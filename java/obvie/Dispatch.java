package obvie;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashSet;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.github.oeuvres.alix.lucene.Alix;
import com.github.oeuvres.alix.web.Webinf;

/**
 * Url dispatcher.
 */
public class Dispatch extends HttpServlet
{
    /** Load bases from WEB-INF/, one time */
    static {
        if (!Webinf.bases) {
            Webinf.bases();
        }
    }

    /** for serialization */
    private static final long serialVersionUID = 1L;
    /** Request attribute name: internal messages for the servlet */
    public static final String OBVIE = "obvie";
    /** Request attribute name: the directory containing bases */
    public static final String CONTEXT_DIR = "baseDir";
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
    static HashSet<String> STOP = new HashSet<String>(
            Arrays.asList(new String[] { "WEB-INF", "static", "jsp", "reload" }));
    /** Absolute folder of properties file and lucene index */
    private File contextDir;

    public void init(ServletConfig config) throws ServletException
    {
        super.init(config);
        contextDir = new File(getServletContext().getRealPath(""));
    }

    public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
    {
        request.setCharacterEncoding("UTF-8");
        String context = request.getContextPath();
        
        String url = request.getRequestURI().substring(context.length());
        Path path = Paths.get(url).normalize();
        if (path.getNameCount() > 5) {
            throw new ServletException("Infinite loop");
        }
        request.setAttribute(CONTEXT_DIR, contextDir);
        if (path.getNameCount() == 0) {
            request.getRequestDispatcher("/jsp/bases.jsp").forward(request, response);
            return;
        }
        String base = path.getName(0).toString();
        // direct access to jsp directory, problem seen with tomcat7 and <jsp:include/>
        if ("jsp".equals(base)) {
            request.getRequestDispatcher(path.toString()).forward(request, response);
            return;
        }

        // reload base list
        if ("reload".equals(base)) {
            Webinf.bases();
            response.sendRedirect(context + "/");
            return;
        }

        
        if (!Alix.hasInstance(base)) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            request.setAttribute(MESSAGE, "[Obvie] {" + base + "} base not known on this server.");
            /* request.setAttribute(REDIRECT, base + "/"); */
            request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
            return;
        }
        
        request.setAttribute(BASE, base);
        // ensure trailing space, redirection
        if (path.getNameCount() == 1 && !url.equals("/" + base + "/")) {
            
            response.sendRedirect(context + "/" + base + "/");
            return;
        }
        // base welcome page
        if (path.getNameCount() == 1) {
            /*
            // ensure trailing space for relative links
            if (!url.equals("/" + base + "/")) {
                // response.sendRedirect(context+"/"+base+"/"); // will not work behind proxy
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                request.setAttribute(MESSAGE,
                        "Bad link, try <a href=\"" + base + "/\">" + base + "</a> (with a slash).");
                request.setAttribute(REDIRECT, base + "/");
                request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
                return;
            }
            */
            request.getRequestDispatcher("/jsp/desk.jsp").forward(request, response);
            return;
        }
        // path inside base
        Path action = path.subpath(1, path.getNameCount());
        // documentation
        if (action.startsWith("help") || action.startsWith("aide")) {
            String page = "";
            if (action.getNameCount() > 1)
                page = action.getName(1).toString();
            request.getRequestDispatcher("/jsp/help.jsp?page=" + page).forward(request, response);
        }
        // Should be a desk component
        String jsp = action.subpath(0, 1).toString();
        String ext = "";
        String pathinfo = "";
        int i;
        // a jsp could be accessed by multiple extensions to modify output format
        if ((i = jsp.lastIndexOf('.')) > 0) {
            ext = jsp.substring(i + 1);
            jsp = jsp.substring(0, i);
        }
        if (action.getNameCount() > 1)
            pathinfo = action.subpath(1, action.getNameCount()).toString();
        // action with no extension
        url = "/jsp/" + jsp + ".jsp";
        if(!new File(contextDir, url).exists()) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            request.setAttribute(MESSAGE, "[Obvie] \"" + url + "\" script not found ");
            /* request.setAttribute(REDIRECT, base + "/"); */
            request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
        }
        
        request.setAttribute(EXT, ext);
        request.setAttribute(PATHINFO, pathinfo);
        // original path will be available as a request attribute
        request.getRequestDispatcher(url).forward(request, response);
    }

    /**
     * Formulaires
     */
    public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
    {
        doGet(request, response);
    }

}
