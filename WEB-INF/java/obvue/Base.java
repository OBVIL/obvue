package obvue;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.InvalidPropertiesFormatException;
import java.util.Properties;

import javax.servlet.ServletException;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerConfigurationException;

import org.apache.lucene.index.IndexWriter;
import org.xml.sax.SAXException;

import alix.lucene.Alix;
import alix.lucene.XMLIndexer;
import alix.lucene.analysis.FrAnalyzer;
import alix.lucene.util.Cooc;
import alix.util.Dir;

public class Base
{
  public void index(File file) throws InvalidPropertiesFormatException, FileNotFoundException, IOException, NoSuchFieldException
  {
    Properties props = new Properties();
    props.loadFromXML(new FileInputStream(file));
    String src = props.getProperty("src");
    if (src == null) throw new NoSuchFieldException("<entry key=\"src\"> est requis pour indiquer le chemin des fichiers à indexer.");
    long time = System.nanoTime();
    String name = file.getName().replaceFirst("\\..+$", "");
    File index = new File(file, name);
    Path path = index.toPath();
    // delete index, faster to recreate
    Dir.rm(path);
    Alix alix = Alix.instance(path, new FrAnalyzer());
    // Alix alix = Alix.instance(path, "org.apache.lucene.analysis.core.WhitespaceAnalyzer");
    IndexWriter writer = alix.writer();
    String[] globs = src.split(" *; *");
    // XMLIndexer.index(writer, globs);
    // index here will be committed and merged but need to be closed to prepare
    writer.close();
    // XMLIndexer.index(writer, threads, "work/xml/.*\\.xml",
    // "/var/www/html/Teinte/xsl/alix.xsl");
    System.out.println("INDEXED in " + ((System.nanoTime() - time) / 1000000) + " ms.");
    time = System.nanoTime();
    Cooc cooc = new Cooc(alix, "text");
    cooc.write();
    System.out.println("Cooc in " + ((System.nanoTime() - time) / 1000000) + " ms.");
    System.out.println("THE END");
  }
  public static void main(String[] args)
  {
  }
}
