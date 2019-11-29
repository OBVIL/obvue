package obvie;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Path;
import java.util.InvalidPropertiesFormatException;
import java.util.Properties;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;

import org.apache.lucene.index.IndexWriter;
import org.xml.sax.SAXException;

import alix.lucene.Alix;
import alix.lucene.SrcFormat;
import alix.lucene.XMLIndexer;
import alix.lucene.analysis.FrAnalyzer;
import alix.lucene.util.Cooc;
import alix.util.Dir;

public class Base
{
  public static String APP = "Obvie";
  static public void index(File file, int threads) throws IOException, NoSuchFieldException, ParserConfigurationException, SAXException, InterruptedException, TransformerException 
  {
    String name = file.getName().replaceFirst("\\..+$", "");
    if (!file.exists()) throw new FileNotFoundException("\n  ["+APP+"] "+file.getAbsolutePath()+"\nFichier de propriétés introuvable ");
    Properties props = new Properties();
    try {
      props.loadFromXML(new FileInputStream(file));
    }
    catch (InvalidPropertiesFormatException e) {
      throw new InvalidPropertiesFormatException("\n  ["+APP+"] "+file+"\nXML, erreur dans le fichier de propriétés.\n"
          +"cf. https://docs.oracle.com/javase/8/docs/api/java/util/Properties.html");
    }
    catch (IOException e) {
      throw new IOException("\n  ["+APP+"] "+file.getAbsolutePath()+"\nLecture impossible du fichier de propriétés.");
    }
    String src = props.getProperty("src");
    if (src == null) throw new NoSuchFieldException("\n  ["+APP+"] "+file+"\n<entry key=\"src\"> est requis pour indiquer le chemin des fichiers XML/TEI à indexer."
        + "\nLes jokers sont autorisés, par exemple : ../../corpus/*.xml");
    String[] globs = src.split(" *[;:] *");
    // resolve globs relative to the folder of the properties field
    File base = file.getParentFile().getCanonicalFile();
    for (int i=0; i < globs.length; i++) {
      if (!globs[i].startsWith("/")) globs[i] = new File(base, globs[i]).getCanonicalPath();
    }
    // test here if it's folder ?
    long time = System.nanoTime();
    File index = new File(file.getParentFile(), name);
    Path path = index.toPath();
    // delete index, faster to recreate
    Dir.rm(path);
    Alix alix = Alix.instance(path, new FrAnalyzer());
    // Alix alix = Alix.instance(path, "org.apache.lucene.analysis.core.WhitespaceAnalyzer");
    IndexWriter writer = alix.writer();
    XMLIndexer.index(writer, globs, SrcFormat.tei, threads);
    // index here will be committed and merged but need to be closed to prepare
    writer.close();
    Cooc cooc = new Cooc(alix, "text");
    cooc.write();
    System.out.println(name+" INDEXED in " + ((System.nanoTime() - time) / 1000000) + " ms.");
  }
  public static void main(String[] args) throws Exception
  {
    if (args == null || args.length < 1) {
      System.out.println("["+APP+"] usage");
      System.out.println("WEB-INF$ java -cp lib/obvie.jar bases/ma_base.xml");
      System.exit(1);
    }
    int threads = Runtime.getRuntime().availableProcessors() - 1;
    int i = 0;
    try {
      int n = Integer.parseInt(args[0]);
      if (n > 0 && n < threads) threads = n;
      i++;
      System.out.println("["+APP+"] threads="+threads);
    }
    catch (NumberFormatException e) {
      
    }
    if (i >= args.length) {
      System.out.println("["+APP+"] usage");
      System.out.println("WEB-INF$ java -cp lib/obvie.jar bases/ma_base.xml");
      System.exit(1);
    }
    for(; i < args.length; i++) {
      index(new File(args[i]), threads);
    }
  }
}
