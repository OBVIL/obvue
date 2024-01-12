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

import com.github.oeuvres.alix.lucene.AlixDocument;
import com.github.oeuvres.alix.lucene.analysis.FrAnalyzer;


public class GallicaIndexer implements Callable<String> 
{
    public static final boolean posix = FileSystems.getDefault().supportedFileAttributeViews().contains("posix");
    /** Name of the lock file */
    public static final String LOCK_FILE = ".~indexing.lock#";
    /** Name of the report file */
    public static final String REPORT_FILE = "report.tsv";
    /** Name of the properties for the base */
    public static final String PROPS_FILE = "props.xml";
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
    /** File to log each get to Gallica */
    private PrintWriter logPrinter;
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
        File propsFile = new File(baseDir, PROPS_FILE);
        try (FileOutputStream output = new FileOutputStream(propsFile)) {
            props.storeToXML(output, "Alix base configuration", StandardCharsets.UTF_8);
        }
        if (posix) {
            Files.setPosixFilePermissions(propsFile.toPath(), PosixFilePermissions.fromString("rw-rw-r--"));
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
        printer.println("    temps\tark       \tessais\ttx. ocr\tcars.\tdate\tauteur\ttitre");
        printer.println(String.format("%s\t%s\t%s", date, baseDir.getName(), label));
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
        IndexWriterConfig conf = new IndexWriterConfig(new FrAnalyzer());
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
        logPrinter = new PrintWriter(
            new BufferedWriter(new OutputStreamWriter(
                new FileOutputStream(new File(baseDir, "download.log"), true), // true to append
                StandardCharsets.UTF_8                  // Set encoding
            )), 
            true // true for autoflush
        ); 
        String date = dateFormat.format(new Date());
        // put an handle on report file now
        // create 
        // loop on arks for download and index
        final long startNano = System.nanoTime();
        GallicaText info = new GallicaText();
        String[] required = {"id", "title", "byline", "year", "bibl", "text"};
        AlixDocument alixDoc = new AlixDocument(required);
        for (String ark: arkList) {
            // 
            if (Thread.currentThread().isInterrupted()) {
                return stop("INTERRUPTION");
            }
            Path htmlPath = Paths.get(htmlDir.toString(), ark + ".html");
            if (Files.exists(htmlPath)) {
                continue;
            }
            alixDoc.id(ark);
            info.reset();
            info.ark = ark;
            try {
                loadGallicaText(alixDoc, info);
            } catch (Exception e) {
                reportPrinter.println(e);
                continue;
            }
            int millis = ThreadLocalRandom.current().nextInt(3000, 5000);
            int essais = 1;
            while (info.status == 429 || info.status == 0) {
                try {
                    Thread.sleep(millis);
                    loadGallicaText(alixDoc, info);
                } 
                catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    return stop("INTERRUPTION");
                }
                catch (Exception e) {
                    reportPrinter.println(e);
                }
                essais++;
                if (millis > 180000) {
                    break;
                }
                millis = millis * 2 + ThreadLocalRandom.current().nextInt(0, millis / 4);
            }
            String status = "" + essais;
            if (!info.indexable) {
                status = "http " + info.status;
            }
            reportPrinter.print(
                duration(startNano)
                + "\t" + "<a target=\"_blank\" href=\""+ info.url + "\">" + ark + "</a>"
                + "\t" + status
                + "\t" + Objects.toString(info.ocr, "")
                + "\t" + ((info.size > 0)?info.size:"")
                + "\t" + Objects.toString(info.date, "")
                + "\t" + Objects.toString(info.byline, "")
                + "\t" + Objects.toString(info.title, "")
                + "\t" + Objects.toString(info.message, "")
            );
            reportPrinter.flush();
            String[] members = {
                Objects.toString(info.byline, null),
                Objects.toString(info.date, null),
                Objects.toString(info.title, null),
            };
            String  bibl = null;
            for (String s: members) {
                if (s == null) continue;
                if (bibl == null) bibl = s;
                else bibl += ". " +s;
            }
            if (bibl != null) {
                alixDoc.bibl(bibl + ".");
            }
            
            // no interesting html
            if (!info.indexable) {
                reportPrinter.println(); // finish report line
                continue;
            }
            final long indexNano = System.nanoTime();
            try {
                Files.write(htmlPath, info.html.getBytes(StandardCharsets.UTF_8));
                if (posix) {
                    Files.setPosixFilePermissions(htmlPath, PosixFilePermissions.fromString("rw-rw-r--"));
                }
                lucene.addDocument(alixDoc.document());
            } catch (Exception e) {
                reportPrinter.println(e);
            }
            reportPrinter.println("\tlucene " + duration(indexNano));
            // wait ?
        }
        lucene.commit();
        // A possible optimization here, the generation of coocs
        return stop("<a href=\".\" target=\"_top\" class=\"button\">Votre corpus est prêt</a>");
    }
    
    public static String duration(final long startNano)
    {
        final long nanos = System.nanoTime() - startNano;
        long durationSec    = nanos/(1000*1000*1000);
        final long sec        = durationSec % 60;
        final long min        = (durationSec /60) % 60;
        final long hour       = (durationSec /(60*60));
        return String.format("% 3d:%02d:%02d", hour,min,sec);
    }

    public String stop(String message) throws IOException
    {
        lucene.close();
        String date = dateFormat.format(new Date());
        reportPrinter.println(String.format("%s\t%s\t%s.", date, label, message));
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
            final long downloadNano = System.nanoTime();
            logPrinter.print(dateFormat.format(new Date())+ " " + info.url);
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
            logPrinter.println(" " + info.status + " " + duration(downloadNano));
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
            else if (info.status == 400) {
                info.message = "ARK malformée, caractère de contrôle incorrect";
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
                        info.ocr = m.group(0);
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
                    alixDoc.textField(text);
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
                        alixDoc.title(s);
                    }
                    if("dc.creator".equalsIgnoreCase(name)) {
                        if (byline.length() > 0) byline.append(". ");
                        final String s = content.replace(". Auteur du texte", "").trim();
                        byline.append(s);
                        alixDoc.author(s);
                    }
                    if("dc.date".equalsIgnoreCase(name) && info.date == null) {
                        Matcher m = patYear.matcher(content);
                        if (m.find()) {
                            try {
                                int year = Integer.parseInt(m.group(0));
                                alixDoc.year(year);
                                info.date = "" + year;
                            }
                            catch (NumberFormatException e) {
                                
                            }
                        }
                    }
                }
                if (byline.length() > 0) {
                    info.byline = byline.toString();
                    alixDoc.byline(info.byline);
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
            reportPrinter.println(String.format("ERROR\t%s\t%s", info.url, e));
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
        protected String ocr;
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
            this.ocr = null;
            this.message = null;
            this.size = 0;
            this.html = null;
            this.byline = null;
            this.date = null;
            this.title = null;
        }
        
        public String toString()
        {
            return "<a target=\"_blank\" href=\""+ url + "\">" + ark + "</a>"
                + "\t" + status
                + "\t" + Objects.toString(message, "")
                + "\t" + ((size > 0)?size:"")
                + "\t" + Objects.toString(date, "")
                + "\t" + Objects.toString(byline, "")
                + "\t" + Objects.toString(title, "")
            ;
        }
    }
}
