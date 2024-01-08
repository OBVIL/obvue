package fr.sorbonne_universite.obtic.obvie;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashSet;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Url dispatcher for obvie indexer
 */
public class Rooter extends HttpServlet
{
    /** for serialization */
    private static final long serialVersionUID = 1L;
    /** Request parameter: the base name. */
    public static final String ARKS = "arks";
    /** Request attribute: the base name. */
    public static final String BASE = "base";
    /** Context init param: base lifetime, in days. */
    public static final String BASELIFE = "baselife";
    /** Request attribute: set of bases, with their properties. */
    public static final String BASE_LIST = "baseList";
    /** Context init param: directory of bases. */
    public static final String DATADIR = "datadir";
    /** Request attribute: original extension requested, like csv or json. */
    public static final String EXT = "ext";
    /** Request attribute: error message for an error page. */
    public static final String MESSAGE = "message";
    /** Request attribute: internal messages for the servlet. */
    public static final String OBVIE = "obvie";
    /** Request attribute: original extension of action. */
    public static final String PATHINFO = "pathinfo";
    /** Context init param: number of allowed indexation tasks. */
    public static final String POOLSIZE = "poolsize";
    /** Context attribute: a FixedThreadPool. */
    public static final String POOL = "pool";
    /** Request attribute: Properties for the base. */
    public static final String PROPS = "props";
    /** Request attribute: URL redirection for client. */
    public static final String REDIRECT = "redirect";
    /** Forbidden names for a corpus. */
    static final HashSet<String> STOP = new HashSet<String>(
        Arrays.asList(new String[] { "WEB-INF", "static", "jsp", "reload" })
    );
    /** Context directory, allow to check jsp existence. */
    private File contextDir;
    /** Directory of bases. */
    private File dataDir;

    @Override
    public void init(ServletConfig config) throws ServletException
    {
        super.init(config);
        contextDir = new File(getServletContext().getRealPath(""));
        ServletContext context = getServletContext();
        final int poolSize = getInteger(POOLSIZE, 10);
        ExecutorService pool = Executors.newFixedThreadPool(poolSize);
        context.setAttribute(POOL, pool);
        context.setAttribute(DATADIR, dataDir());
        context.setAttribute(BASELIFE, getInteger(BASELIFE, 10));
    }
    
    public Integer getInteger(final String name, final int fallback)
    {
        ServletContext context = getServletContext();
        String value = context.getInitParameter(name);
        if (value != null && !value.isEmpty()) {
            try {
                Integer val = Integer.valueOf(value);
                return val;
            }
            catch(NumberFormatException e) {
                // inform ?
            }
        }
        return Integer.valueOf(fallback);
    }

    /**
     * Get basedir to write 
     * 
     * @return
     * @throws ServletException
     */
    private File dataDir() throws ServletException
    {
        ServletContext context = getServletContext();
        String value = context.getInitParameter(DATADIR); // dir of bases
        if(value == null || value.isEmpty()) {
            value = getServletConfig().getInitParameter(DATADIR);
        }
        if(value == null || value.isEmpty()) {
            value = getServletContext().getRealPath("") + "WEB-INF/data/";
        }
        File file = new File(value);
        if (!file.isAbsolute()) {
            throw new ServletException("Init param datadir is not an absolute file path: <Parameter name=\"datadir\" value=\"" + value + "\" override=\"false\"/>");
        }
        if (!file.exists() && !file.mkdirs()) {
            throw new ServletException("Init param datadir, impossible to create: <Parameter name=\"datadir\" value=\"" + value + "\" override=\"false\"/>");
        }
        else if (!file.isDirectory()) {
            throw new ServletException("Init param datadir, exists but is not a directory: <Parameter name=\"datadir\" value=\"" + value + "\" override=\"false\"/>");
        }
        else if (!file.canWrite()) {
            throw new ServletException("Init param datadir, is a directory but is not writable: <Parameter name=\"datadir\" value=\"" + value + "\" override=\"false\"/>");
        }
        return file;
    }
    
    @Override
    public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
    {
        request.setCharacterEncoding("UTF-8");
        String context = request.getContextPath();
        // url = /context/base/action
        String url = request.getRequestURI().substring(context.length());
        Path path = Paths.get(url).normalize();
        if (path.getNameCount() > 5) {
            throw new ServletException("Infinite loop");
        }
        if (path.getNameCount() == 0) {
            request.getRequestDispatcher("/jsp/gallicobvie.jsp").forward(request, response);
            return;
        }
        String base = path.getName(0).toString();
        // direct access to jsp directory, problem seen with tomcat7 and <jsp:include/>
        if ("jsp".equals(base)) {
            request.getRequestDispatcher(path.toString()).forward(request, response);
            return;
        }
        
        if (STOP.contains(base)) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            request.setAttribute(MESSAGE, "Page inconnue");
            request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
        }

        request.setAttribute(BASE, base); // 
        File baseDir = new File(dataDir, base);
        // ensure trailing space, redirection
        if (path.getNameCount() == 1 && !url.equals("/" + base + "/")) {
            response.sendRedirect(context + "/" + base + "/");
            return;
        }
        // base does not exist, arks are sended, start loading
        if (!baseDir.exists() && request.getParameter(ARKS) != null) {
            request.getRequestDispatcher("/jsp/charger.jsp").forward(request, response);
            return;
        }
        // base does not exist, offer form to send arks
        else if (!baseDir.exists()) {
            request.getRequestDispatcher("/jsp/arks.jsp").forward(request, response);
            return;
        }
        // base is locked show progress
        else if (!new File(baseDir, GallicaIndexer.LOCK_FILE).exists()) {
            request.getRequestDispatcher("/jsp/progress.jsp").forward(request, response);
            return;
        }
        
        // base welcome page
        if (path.getNameCount() == 1) {
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
            // request.setAttribute(REDIRECT, base + "/"); 
            request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
        }
        
        request.setAttribute(EXT, ext);
        request.setAttribute(PATHINFO, pathinfo);
        // original path will be available as a request attribute
        request.getRequestDispatcher(url).forward(request, response);
    }

    @Override
    public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
    {
        doGet(request, response);
    }

}
