package fr.sorbonne_universite.obtic.obvie;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.github.oeuvres.alix.util.Chain;

/**
 * Url dispatcher for obvie indexer
 */
public class Rooter extends HttpServlet {
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
    /** Request attribute: debug informations for the rewrite process. */
    public static final String DEBUG = "ext";
    /** Request attribute: original extension requested, like csv or json. */
    public static final String EXT = "ext";
    /** Request attribute: relative link to context. */
    public static final String HREF_CONTEXT = "hrefcontext";
    /** Context attribute: handles on tasks submitted to pool. */
    public static final String FUTURES = "futures";
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
            Arrays.asList(new String[] { "WEB-INF", "static", "jsp", "reload" }));
    /** Request attribute: requested URL. */
    public static final String URL = "url";
    /** Context directory, allow to check jsp existence. */
    private File contextDir;
    /** Directory of bases. */
    private File dataDir;
    /** Pool of thread, for destruction at the end */
    private ExecutorService pool;
    /** Dictionary of Futures for threads submitted to the pool */
    private HashMap<String, Future<String>> futures;

    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        contextDir = new File(getServletContext().getRealPath(""));
        ServletContext context = getServletContext();
        final int poolSize = getInteger(POOLSIZE, 10);
        pool = Executors.newFixedThreadPool(poolSize);
        context.setAttribute(POOL, pool);
        futures = new HashMap<String, Future<String>>();
        context.setAttribute(FUTURES, futures);
        dataDir = dataDir();
        context.setAttribute(DATADIR, dataDir);
        context.setAttribute(BASELIFE, getInteger(BASELIFE, 10));
    }

    @Override
    public void destroy() {
        super.destroy();
        pool.shutdown(); // Disable new tasks from being submitted
        // loop on futures and send terminal signal
        for (Map.Entry<String, Future<String>> entry : futures.entrySet()) {
            String key = entry.getKey();
            Future<String> future = entry.getValue();
            future.cancel(true);
        }
        try {
            // Wait a while for existing tasks to terminate
            if (!pool.awaitTermination(5, TimeUnit.SECONDS)) {
                pool.shutdownNow(); // Cancel currently executing tasks
                // Wait a while for tasks to respond to being cancelled
                if (!pool.awaitTermination(60, TimeUnit.SECONDS)) {
                    System.err.println("Pool did not terminate");
                }
            }
        } catch (InterruptedException ie) {
            // (Re-)Cancel if current thread also interrupted
            pool.shutdownNow();
            // Preserve interrupt status
            Thread.currentThread().interrupt();
        }
    }

    public Integer getInteger(final String name, final int fallback) {
        ServletContext context = getServletContext();
        String value = context.getInitParameter(name);
        if (value != null && !value.isEmpty()) {
            try {
                Integer val = Integer.valueOf(value);
                return val;
            } catch (NumberFormatException e) {
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
    private File dataDir() throws ServletException {
        ServletContext context = getServletContext();
        String value = context.getInitParameter(DATADIR); // dir of bases
        if (value == null || value.isEmpty()) {
            value = getServletConfig().getInitParameter(DATADIR);
        }
        if (value == null || value.isEmpty()) {
            value = getServletContext().getRealPath("") + "WEB-INF/data/";
        }
        File file = new File(value);
        if (!file.isAbsolute()) {
            throw new ServletException(
                    "Init param datadir is not an absolute file path: <Parameter name=\"datadir\" value=\"" + value
                            + "\" override=\"false\"/>");
        }
        if (!file.exists() && !file.mkdirs()) {
            throw new ServletException("Init param datadir, impossible to create: <Parameter name=\"datadir\" value=\""
                    + value + "\" override=\"false\"/>");
        } else if (!file.isDirectory()) {
            throw new ServletException(
                    "Init param datadir, exists but is not a directory: <Parameter name=\"datadir\" value=\"" + value
                            + "\" override=\"false\"/>");
        } else if (!file.canWrite()) {
            throw new ServletException(
                    "Init param datadir, is a directory but is not writable: <Parameter name=\"datadir\" value=\""
                            + value + "\" override=\"false\"/>");
        }
        return file;
    }

    @Override
    public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String context = request.getContextPath();
        // url = /context/base/action
        // request.getPathInfo() does not return what is needed
        // normalize odd /// //
        String url = request.getRequestURI().replaceAll("/+", "/").substring(context.length());
        String[] parts = new Chain(url).split('/');
        // keep original url request after redirections
        request.setAttribute(URL, url);
        // Path.relativize() use \ on windows, URI.relativize() needs absolute URI with protocol
        int count = (int)url.chars().filter(ch -> ch =='/').count() - 1;
        String hrefContext = "../".repeat(count);
        
        final String debug = ""
            + "  requestURI=" + request.getRequestURI().replaceAll("/+", "/")
            + ", contextPath=" + request.getContextPath()
            + ", url=" + url
            + ", parts=" + Arrays.toString(parts)
            + ", hrefContext=" + hrefContext;
        
        request.setAttribute(DEBUG, debug);
        request.setAttribute(HREF_CONTEXT, hrefContext);
        
        if (parts.length > 5) {
            throw new ServletException("Infinite loop");
        }
        if (parts.length == 0) {
            request.getRequestDispatcher("/jsp/gallicobvie.jsp").forward(request, response);
            return;
        }
        String base = parts[0];
        // direct access to jsp directory, problem seen with tomcat7 and <jsp:include/>
        /*
        if ("jsp".equals(base)) {
            request.getRequestDispatcher(path.toString()).forward(request, response);
            return;
        }
        */

        if (STOP.contains(base)) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            request.setAttribute(MESSAGE, "Page inconnue");
            request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
        }

        request.setAttribute(BASE, base); //
        File baseDir = new File(dataDir, base);
        // ensure trailing space, redirection
        if (parts.length == 1 && !url.equals("/" + base + "/")) {
            response.sendRedirect(context + "/" + base + "/");
            return;
        }
        
        // base does not yet exist
        if (parts.length == 1 && !baseDir.exists()) {
            // arks are sended, start loading
            if (request.getParameter(ARKS) != null) {
                request.getRequestDispatcher("/jsp/load.jsp").forward(request, response);
            }
            // offer form to send arks
            else  {
                request.getRequestDispatcher("/jsp/arks.jsp").forward(request, response);
            }
            return;
        }
        // base is created, welcome pages 
        else if (parts.length == 1) {
            // lock file, indexation in progress
            if (new File(baseDir, GallicaIndexer.LOCK_FILE).exists()) {
                request.getRequestDispatcher("/jsp/progress.jsp").forward(request, response);
            }
            else {
                request.getRequestDispatcher("/jsp/desk.jsp").forward(request, response);
            }
            return;
        }
        // path inside base
        String action = parts[1];
        // documentation
        if (action.startsWith("help") || action.startsWith("aide")) {
            String page = "";
            if (parts.length > 2) {
                page = parts[2];
            }
            request.getRequestDispatcher("/jsp/help.jsp?page=" + page).forward(request, response);
        }
        // Should be a desk component
        String jsp = action;
        String ext = "";
        StringBuilder pathinfo = new StringBuilder();
        final int pos;
        // a jsp could be accessed by multiple extensions to modify output format
        if ((pos = action.lastIndexOf('.')) > 0) {
            ext = action.substring(pos + 1);
            jsp = action.substring(0, pos);
        }
        // some more parameters for the action
        if (parts.length > 2) {
            boolean first = true;
            for (int i = 2; i < parts.length; i++) {
                if (first) {
                    first = false;
                }
                else {
                    pathinfo.append("/");
                }
                pathinfo.append(parts[i]);
            }
        }
        // action with no extension
        final String jspFile = "/jsp/" + jsp + ".jsp";
        if (!new File(contextDir, jspFile).exists()) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            request.setAttribute(MESSAGE, "[Obvie] \"" + url + "\" script not found. url=" + request.getAttribute(URL));
            // request.setAttribute(REDIRECT, base + "/");
            request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
        }

        request.setAttribute(EXT, ext);
        request.setAttribute(PATHINFO, pathinfo.toString());
        request.getRequestDispatcher(jspFile).forward(request, response);
    }

    @Override
    public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        doGet(request, response);
    }

}
