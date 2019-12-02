package obvie;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Properties;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import alix.lucene.analysis.FrDics;
import alix.lucene.analysis.tokenattributes.CharsAtt;

/**
 * In an MVC model, this servlet is the global controller for the Obvie app.
 * Model is the lucene index and alix java, View is the jsp pages.
 * It is mainly an url dispatcher.
 */
public class Dispatch extends HttpServlet
{
  static {
    for (String w : new String[] {"dire"}) {
      FrDics.STOP.add(new CharsAtt(w));
    }
  }
  /** for serialization */
  private static final long serialVersionUID = 1L;
  /** Request attribute name: internal messages for the servlet */
  public static final String OBVIE = "obvie";
  /** Request attribute name: the directory containing bases */
  public static final String BASE_DIR = "baseDir";
  /** Request attribute name: set of bases, with their properties */
  public static final String BASE_LIST = "baseList";
  /** Request attribute name: the base name */
  public static final String BASE = "base";
  /** Request attribute name: Properties for the base */
  public static final String PROPS = "props";
  /** Request attribute name: original extension requested, like csv or json */
  public static final String EXT = "ext";
  /** Request attribute name: original extension of action */
  public static final String PATHINFO = "pathinfo";
  /** Request attribute name: error message for an error page */
  public static final String MESSAGE = "message";
  /** Request attribute name: URL redirection for client */
  public static final String REDIRECT = "redirect";
  /** forbidden name for corpus */
  static HashSet<String> STOP = new HashSet<String>(Arrays.asList(new String[] {"WEB-INF", "static", "jsp", "reload"}));
  /** Absolute folder of properties file and lucene index */
  private String baseDir;
  /** List of available bases with properties */
  private HashMap<String, Properties> baseList = new HashMap<>();
  

  public void init(ServletConfig config) throws ServletException
  {
    super.init(config);
    props();
  }

  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {
    request.setCharacterEncoding("UTF-8");
    String stack = (String)request.getAttribute(OBVIE);
    if (stack == null) {
      stack = request.getRequestURI();
      request.setAttribute(OBVIE, stack);
    }
    else {
      stack += "\n"+request.getRequestURI();
      if (stack.length() > 1024) throw new ServletException("[Obvie] infinite loop error \n"+stack);
    }
    String context = request.getContextPath(); 
    String url = request.getRequestURI().substring(context.length());
    Path path = Paths.get(url).normalize();
    request.setAttribute(BASE_DIR, baseDir);
    if (path.getNameCount() == 0) {
      request.setAttribute(BASE_LIST, baseList);
      request.getRequestDispatcher("/jsp/bases.jsp").forward(request, response);
      return;
    }
    String base = path.getName(0).toString();
    // direct access to jsp directory, problems seen with tomcat7 and <jsp:include/>
    if ("jsp".equals(base)) {
      request.getRequestDispatcher(path.toString()).forward(request, response);
      return;
    }
    
    // reload base list
    if ("reload".equals(base)) {
      props();
      throw new ServletException("[Obvie] reload base list.");
    }
    
    Properties props = baseList.get(base);
    if (props == null || props.contains("error")) {
      throw new ServletException("[Obvie] {"+base+ "} base not known on this server. \n"+stack);
    }
    request.setAttribute(BASE, base);
    request.setAttribute(PROPS, props);
    // base welcome page
    if (path.getNameCount() == 1) {
      // ensure trailing space for relative links
      if (!url.equals("/"+base+"/")) {
        // response.sendRedirect(context+"/"+base+"/"); // will not work behind proxy
        response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        request.setAttribute(MESSAGE, "Bad link, try <a href=\""+base+"/\">"+base+"</a> (with a slash).");
        request.setAttribute(REDIRECT, base+"/");
        request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
        return;
      }
      request.getRequestDispatcher("/jsp/desk.jsp").forward(request, response);
      return;
    }
    // path inside base
    Path action = path.subpath(1, path.getNameCount());
    // documentation
    if (action.startsWith("help") || action.startsWith("aide")) {
      String page = "";
      if (action.getNameCount() > 1) page= action.getName(1).toString();
      request.getRequestDispatcher("/jsp/help.jsp?page="+page).forward(request, response);
    }
    // Should be a desk component
    String jsp = action.subpath(0, 1).toString();
    String ext = "";
    String pathinfo = "";
    int i;
    // a jsp could be accessed by multiple extensions to modify output format
    if (( i = jsp.lastIndexOf('.')) > 0) {
      ext = jsp.substring(i+1);
      jsp = jsp.substring(0, i);
    }
    if (action.getNameCount() > 1) pathinfo = action.subpath(1, action.getNameCount()).toString();
    // action with no extension
    jsp += ".jsp";
    request.setAttribute(EXT, ext);
    request.setAttribute(PATHINFO, pathinfo);
    // original path will be available as a request attribute 
    request.getRequestDispatcher("/jsp/"+jsp).forward(request, response);
  }
  
  /** 
   * Formulaires
   */
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
  {
    doGet(request, response);
  }


  /**
   * Loop on a folder containing configuration files.
   * 
   * @throws ServletException
   */
  private void props() throws ServletException
  {
    baseDir = getServletContext().getRealPath("WEB-INF/bases");
    // ensure trrailing slash (getRealPath() could fiffer between tomcat versions)
    if(!baseDir.endsWith("/")) baseDir += "/";
    File dir = new File(baseDir);
    File[] ls = dir.listFiles();
    baseList.clear();
    for (File file : ls) {
      if (file.isDirectory()) continue;
      String filename = file.getName();
      if (filename.startsWith("_")) continue;
      if (filename.startsWith(".")) continue;
      int i = filename.lastIndexOf('.');
      String ext = filename.substring(i);
      if (!".xml".equals(ext)) continue;
      String code = filename.substring(0, i);
      Properties props = new Properties();
      if (STOP.contains(code)) {
        props.put("error", "<i>"+code+"</i>, nom de base interdit.");
      }
      if (!file.canRead()) {
        props.put("error", "<i>"+code+"</i>, erreur de lecture.");
      }
      else {
        try {
          props.loadFromXML(new FileInputStream(file));
        }
        catch (Exception e) {
          props.put("error", "<i>"+code+"</i>, configuration en cours.");
        }
      }
      if (!new File(dir, code).isDirectory()) {
        props.put("error", "<i>"+code+"</i>, chargement en cours.");
      }
      baseList.put(code, props);
    }
  }
}
