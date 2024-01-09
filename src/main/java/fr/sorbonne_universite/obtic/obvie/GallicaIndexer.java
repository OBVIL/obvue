package fr.sorbonne_universite.obtic.obvie;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.Writer;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.PosixFilePermissions;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;
import java.util.Objects;
import java.util.Properties;
import java.util.concurrent.Callable;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.lucene.analysis.standard.StandardAnalyzer;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.StringField;
import org.apache.lucene.document.TextField;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.IndexWriterConfig;
import org.apache.lucene.index.IndexWriterConfig.OpenMode;
import org.apache.lucene.store.Directory;
import org.apache.lucene.store.FSDirectory;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import com.github.oeuvres.alix.lucene.Alix;
import com.github.oeuvres.alix.lucene.AlixDocument;
import com.github.oeuvres.alix.lucene.analysis.FrAnalyzer;


public class GallicaIndexer implements Callable<String> 
{
    public static final boolean posix = FileSystems.getDefault().supportedFileAttributeViews().contains("posix");
    /** Name of the lock file */
    public static final String LOCK_FILE = ".~indexing.lock#";
    /** Name of the report file */
    public static final String REPORT_FILE = "report.txt";
    /** Name of the lucene directory */
    public static final String LUCENE = "lucene";
    /** XML date format */
    private static final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    /** Regex to extract OCR rate, especially 0% for no text */
    private static final Pattern patOcr = Pattern.compile("[\\d\\.,]+%");
    /** Regex to extract year */
    private static final Pattern patYear = Pattern.compile("\\d+");
    /** Name of this base */
    private final String label;
    /** Folder for the document base */
    private final File baseDir;
    /** Array of Gallica arks */
    private final String[] arkList;
    /** Lock File */
    private final File lockFile;
    /** Save downloaded files. */
    private final File htmlDir;
    /** Report file. */
    private final File reportFile;
    /** File to write in for reports. */
    private PrintWriter reportPrinter;
    /** Lucene writer */
    private IndexWriter lucene;
    


    /**
     * Submit task, test now if everything is possible. Lock only if indexation has starting.
     * 
     * @param label
     * @param arkList
     * @param baseDir
     * @throws IOException 
     */
    public GallicaIndexer(String label, final String[] arkList, final File baseDir) throws IOException
    {
        if (baseDir == null) {
            throw new IllegalArgumentException("Required directory for a base to write in is null.");
        }
        if (!baseDir.exists() && !baseDir.mkdir()) {
            throw new IllegalArgumentException(String.format("Impossible de créer la base dans: %s", baseDir));
        }
        if (!baseDir.canWrite()) {
            throw new IllegalArgumentException(String.format("Impossible d’écrire la base dans: %s", baseDir));
        }
        if (posix) {
            Files.setPosixFilePermissions(baseDir.toPath(), PosixFilePermissions.fromString("rwxrwxr-x"));
        }
        // permissions
        this.baseDir = baseDir;
        lockFile = new File(baseDir, LOCK_FILE);
        if (lockFile.exists()) {
            throw new IllegalArgumentException(String.format("Un autre utilisateur à lancé une indexation pour cette base: %s", baseDir));
        }
        // open lu
        
        if (label == null || "".equals(label.trim())) {
            label = baseDir.getName();
        }
        
        
        Properties props = new Properties();
        props.setProperty("label", label);
        htmlDir = new File(baseDir, "html");
        htmlDir.mkdir();
        if (posix) {
            Files.setPosixFilePermissions(htmlDir.toPath(), PosixFilePermissions.fromString("rwxrwxr-x"));
        }

        props.setProperty("src", "html/*.html");
        props.setProperty("lucene", "lucene/");
        File configFile = new File(baseDir, "config.xml");
        try (FileOutputStream output = new FileOutputStream(configFile)) {
            props.storeToXML(output, "Alix base configuration", StandardCharsets.UTF_8);
        }
        if (posix) {
            Files.setPosixFilePermissions(configFile.toPath(), PosixFilePermissions.fromString("rw-rw-r--"));
        }

        this.label = label;
        this.arkList = arkList;
        reportFile = new File(baseDir, REPORT_FILE);
        PrintWriter printer = new PrintWriter(new BufferedWriter(
            new OutputStreamWriter(
                new FileOutputStream(reportFile, true), // true to append
                StandardCharsets.UTF_8                  // Set encoding
            )
        ));
        String date = dateFormat.format(new Date());
        printer.println(String.format("%s — %s, tâche soumise.", date, label));
        printer.close(); // close now in cas of retarting
        if (posix) {
            Files.setPosixFilePermissions(reportFile.toPath(), PosixFilePermissions.fromString("rw-rw-r--"));
        }
    }
    
    
    @Override
    public String call() throws IOException, InterruptedException {
        lockFile.createNewFile();
        if (posix) {
            Files.setPosixFilePermissions(lockFile.toPath(), PosixFilePermissions.fromString("rw-rw-r--"));
        }
        Path lucenePath = Paths.get(baseDir.getCanonicalPath(), LUCENE);
        IndexWriterConfig conf = new IndexWriterConfig(new StandardAnalyzer());
        // create for now
        conf.setOpenMode(OpenMode.CREATE);
        Directory dir = FSDirectory.open(lucenePath);
        lucene = new IndexWriter(dir, conf);
        
        reportPrinter = new PrintWriter(
            new BufferedWriter(new OutputStreamWriter(
                new FileOutputStream(reportFile, true), // true to append
                StandardCharsets.UTF_8                  // Set encoding
            )), 
            true // true for autoflush
        ); 
        String date = dateFormat.format(new Date());
        reportPrinter.println(String.format("%s — %s, tâche démarrée.", date, label));

        // 
        // put an handle on report file now
        // create 
        // loop on arks for download and index
        final long startNano = System.nanoTime();
        GallicaText info = new GallicaText();
        String[] required = {"title", "byline", "year"};
        AlixDocument alixDoc = new AlixDocument(required);
        for (String ark: arkList) {
            // 
            if (Thread.currentThread().isInterrupted()) {
                return stop("INTERRUPTION");
            }
            File htmlFile = new File(htmlDir, ark + ".html");
            if (htmlFile.exists()) {
                continue;
            }
            alixDoc.id(ark);
            info.reset();
            info.ark = ark;
            loadGallicaText(alixDoc, info);
            int millis = ThreadLocalRandom.current().nextInt(3000, 5000);
            while (info.status == 429 || info.status == 400 || info.status == 0) {
                try {
                    Thread.sleep(millis);
                } 
                catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    return stop("INTERRUPTION");
                }
                loadGallicaText(alixDoc, info);
                if (millis > 180000) {
                    break;
                }
                millis = millis * 2 + ThreadLocalRandom.current().nextInt(0, millis / 4);
            }
            final long nanos = System.nanoTime() - startNano;
            long durationSec    = nanos/(1000*1000*1000);
            final long sec        = durationSec % 60;
            final long min        = (durationSec /60) % 60;
            final long hour       = (durationSec /(60*60));
            String duration = String.format("% 3d:%02d:%02d", hour,min,sec);
            reportPrinter.println(duration + "\t" + info);
            // no interesting html
            if (!info.indexable) {
                continue;
            }
            Writer out = new BufferedWriter(new OutputStreamWriter(
                    new FileOutputStream(htmlFile), StandardCharsets.UTF_8));
            out.write(info.html);
            out.flush();
            out.close();
            if (posix) {
                Files.setPosixFilePermissions(htmlFile.toPath(), PosixFilePermissions.fromString("rw-rw-r--"));
            }
            reportPrinter.println(String.format("% 3d:%02d:%02d", hour,min,sec) + " indexing start");
            /*
            org.apache.lucene.document.Document luceneDoc = new org.apache.lucene.document.Document();
            luceneDoc.add(new StringField("id", ark, Field.Store.YES));
            luceneDoc.add(new TextField("text", "Petit texte", Field.Store.YES));
            */
            org.apache.lucene.document.Document luceneDoc = alixDoc.document();
            lucene.addDocument(luceneDoc);
            reportPrinter.println(String.format("% 3d:%02d:%02d", hour,min,sec) + " indexing stop");
            // wait probably not needed here, indexatoin should do the job
            // millis = ThreadLocalRandom.current().nextInt(1000, 2000);
            // TimeUnit.MILLISECONDS.sleep(millis);
        }
        lucene.commit();
        // A possible optimization here, the generation of coocs
        return stop("OK, FIN");
    }

    public String stop(String message) throws IOException
    {
        lucene.close();
        String date = dateFormat.format(new Date());
        reportPrinter.println(String.format("%s — %s, %s.", date, label, message));
        reportPrinter.close();
        // free the lock
        if (lockFile.exists()) {
            lockFile.delete();
        }
        return message;
    }
    
    public void loadGallicaText(final AlixDocument alixDoc, final GallicaText info)
    {
        
        info.url = "https://gallica.bnf.fr/ark:/12148/" + info.ark + ".texteBrut";
        Connection.Response response = null;
        try {
            response = Jsoup.connect(info.url)
                .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0")
                .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
                .header("Accept-Encoding", "gzip, deflate, br")
                .header("Accept-Language", "fr,fr-FR;")
                .header("Cache-Control", "no-cache")
                .ignoreHttpErrors(true)
                .followRedirects(false)
                .timeout(60000) // 60 s. timeout
                .execute();
            info.status = response.statusCode();
            if (info.status == 429) {
                return;
            }
            if (info.status == 408) {
                return;
            }
            else if (info.status == 403) {
                info.message = "N'est disponible que sur accréditation";
                return;
            }
            else if (info.status == 302) {
                info.message = response.header("Location");
                return;
            }
            else if (info.status == 200) {
                Document doc = response.parse();
                Element el = doc.selectFirst("p:contains(taux de reconnaissance)");
                if (el != null) {
                    Matcher m = patOcr.matcher(el.text());
                    if (m.find()) {
                        info.message = m.group(0);
                    }
                }
                info.html = doc.outerHtml();
                // seems at least one page ?
                // contents to index
                String text = doc.body().html();
                int pos = text.indexOf("<hr>");
                if (pos < 0) pos = text.indexOf("<hr/>");
                if (pos > 0) {
                    text = text.substring(pos);
                    info.size = text.length();
                    alixDoc.text("Deux ou trois mots");
                    info.indexable = true;
                }
                else {
                    reportPrinter.println("Inindexable ?");
                }
                Elements metas = doc.getElementsByTag("meta");
                StringBuilder byline = new StringBuilder();
                for (Element prop : metas) {
                    final String content = prop.attr("content");
                    final String name = prop.attr("name");
                    if("dc.title".equalsIgnoreCase(name) && info.title == null) {
                        final String s = content.replace(" | Gallica", "");
                        info.title = s;
                        // alixDoc.title(s);
                    }
                    if("dc.creator".equalsIgnoreCase(name)) {
                        if (byline.length() > 0) byline.append(". ");
                        final String s = content.replace(". Auteur du texte", "").trim();
                        byline.append(s);
                        // alixDoc.author(s);
                    }
                    if("dc.date".equalsIgnoreCase(name) && info.date == null) {
                        info.date = content;
                        Matcher m = patYear.matcher(content);
                        if (m.find()) {
                            try {
                                int year = Integer.parseInt(m.group(0));
                                // alixDoc.year(year);
                            }
                            catch (NumberFormatException e) {
                                
                            }
                        }
                    }
                }
                if (byline.length() > 0) {
                    final String s = byline.toString();
                    info.byline = s;
                    // alixDoc.byline(s);
                }
                return;
            }
            else {
                reportPrinter.println(print(response.headers()));
                return;
            } 

        }
        catch(SocketTimeoutException e) {
            return;
        }
        catch (IOException e) {
            reportPrinter.println(String.format("io — %s, %s", info.url, e));
            return;
        }
    }
    
    public static String print(Map<String, String> map) {
        StringBuilder builder = new StringBuilder();
        for (Map.Entry<String, String> entry : map.entrySet()) {
            builder.append(entry.getKey());
            builder.append(": ");
            builder.append(entry.getValue());
            builder.append("\n");
        }
        return builder.toString();
    }
    
    
    /**
     * An object to cary minimal information about a Gallica text
     */
    static class GallicaText
    {
        protected String ark;
        protected boolean indexable;
        protected String url;
        protected int status;
        protected String message;
        protected int size;
        protected String byline;
        protected String date;
        protected String title;
        protected String html;
        
        public void reset()
        {
            this.ark = null;
            this.indexable = false;
            this.url = null;
            this.status = 0;
            this.message = null;
            this.size = 0;
            this.html = null;
            this.byline = null;
            this.date = null;
            this.title = null;
        }
        
        public String toString()
        {
            return ark
                + "\t" + status
                + "\t" + Objects.toString(message, "")
                + "\t" + ((size > 0)?size:"")
                + "\t" + Objects.toString(byline, "")
                + "\t" + Objects.toString(date, "")
                + "\t" + Objects.toString(title, "")
            ;
        }
    }
}
