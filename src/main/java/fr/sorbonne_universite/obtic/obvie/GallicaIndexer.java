package fr.sorbonne_universite.obtic.obvie;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;


public class GallicaIndexer implements Runnable 
{
    /** Name of the lock file */
    public static final String LOCK_FILE = ".~indexing.lock#";
    /** Regex to extract OCR rate, especially 0% for no text */
    private static final Pattern patOcr = Pattern.compile("[\\d\\.,]+%");
    /** Folder for the document base */
    private File baseDir;
    /** Array of Gallica arks */
    private String[] arkList;
    /** Lock File */

    public GallicaIndexer(final String[] arkList, final File baseDir)
    {
        this.baseDir = baseDir;
        this.arkList = arkList;
    }
    
    @Override
    public void run() {
        // check if locked
        
    }

    
    public static void loadGallicaText(GallicaText info)
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
                .timeout(5000)
                .execute();
            info.status = response.statusCode();
            if (info.status == 429) {
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
                // seems at least one page ?
                if (doc.selectFirst("hr:eq(2)") != null) {
                    info.html = doc.outerHtml();
                    /*
                    info.html = doc.body().html();
                    int pos = info.html.indexOf("<hr>");
                    if (pos < 0) pos = info.html.indexOf("<hr/>");
                    info.html = info.html.substring(pos);
                    info.size = info.html.length();
                    */
                }
                Elements metas = doc.getElementsByTag("meta");
                StringBuilder creator = new StringBuilder();
                for (Element prop : metas) {
                    String content = prop.attr("content");
                    String name = prop.attr("name");
                    if("dc.title".equalsIgnoreCase(name) && info.title == null) {
                        info.title = content.replace(" | Gallica", "");
                    }
                    if("dc.creator".equalsIgnoreCase(name)) {
                        if (creator.length() > 0) creator.append(". ");
                        creator.append(content.replace(". Auteur du texte", ""));
                    }
                    if("dc.date".equalsIgnoreCase(name) && info.date == null) {
                        info.date = content;
                    }
                }
                if (creator.length() > 0) {
                    info.creator = creator.toString();
                }
                return;
            }
            else {
                System.err.println(print(response.headers()));
                return;
            } 

        } 
        catch (IOException e) {
            System.out.println("io - "+e);
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
    
    public static void main(String[] args) throws IOException, InterruptedException {
        // read a list of arks
        final long startNano = System.nanoTime();
        Path path = Paths.get("C:/code/alix/work/arks/arks.txt");
        List<String> arks = Files.readAllLines(path, StandardCharsets.UTF_8);
        GallicaText info = new GallicaText();
        for (String ark: arks) {
            File file = new File("C:/code/alix/work/arks/html/" + ark + ".html");
            if (file.exists()) {
                continue;
            }
            if (!file.getParentFile().exists()) {
                file.getParentFile().mkdirs();
            }
            info.reset();
            info.ark = ark;
            loadGallicaText(info);
            int millis = ThreadLocalRandom.current().nextInt(30000, 35000);
            while (info.status == 429 || info.status == 400) {
                TimeUnit.MILLISECONDS.sleep(millis);
                loadGallicaText(info);
                if (millis > 5000000) {
                    break;
                }
                millis = millis * 2 + ThreadLocalRandom.current().nextInt(0, millis / 2);
            }
            millis = ThreadLocalRandom.current().nextInt(1000, 2000);
            final long nanos = System.nanoTime() - startNano;
            long durationSec    = nanos/(1000*1000*1000);
            final long sec        = durationSec % 60;
            final long min        = (durationSec /60) % 60;
            final long hour       = (durationSec /(60*60));
            String duration = String.format("% 3d:%02d:%02d", hour,min,sec);
            System.out.println(duration + "\t" + info);
            if (info.html != null) {
                try (Writer out = new BufferedWriter(new OutputStreamWriter(
                    new FileOutputStream(file), StandardCharsets.UTF_8))) {
                    out.append(info.html);
                    out.flush();
                } catch (Exception e) {
                    System.err.println(e.getMessage());
                }
            }
            TimeUnit.MILLISECONDS.sleep(millis);
        }
    }
    
    /**
     * An object to cary minimal information about a Gallica text
     */
    static class GallicaText
    {
        protected String ark;
        protected String url;
        protected int status;
        protected String message;
        protected int size;
        protected String creator;
        protected String date;
        protected String title;
        protected String html;
        
        public void reset()
        {
            this.ark = null;
            this.url = null;
            this.status = 0;
            this.message = null;
            this.size = 0;
            this.html = null;
            this.creator = null;
            this.date = null;
            this.title = null;
        }
        
        public String toString()
        {
            return ark
                + "\t" + status
                + "\t" + Objects.toString(message, "")
                + "\t" + ((size > 0)?size:"")
                + "\t" + Objects.toString(creator, "")
                + "\t" + Objects.toString(date, "")
                + "\t" + Objects.toString(title, "")
            ;
        }
    }
}
