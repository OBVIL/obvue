<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="java.util.concurrent.Callable" %>
<%@ page import="java.util.concurrent.ExecutorService" %>
<%@ page import="java.util.concurrent.Future" %>
<%@ page import="java.util.logging.Logger" %>
<%@ page import="java.util.logging.Level" %>
<%@ page import="java.util.Map" %>
<%@ page import="fr.sorbonne_universite.obtic.obvie.GallicaIndexer"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter"%>
<%! @SuppressWarnings("unchecked") %>
<%

Logger logger = Logger.getLogger(this.getClass().getName());
final ServletContext servletContext = pageContext.getServletContext();
final File dataDir = (File)servletContext.getAttribute(Rooter.DATADIR);
final String base = (String)request.getAttribute(Rooter.BASE);
final File baseDir = new File(dataDir, base);
final File lockFile = new File(baseDir, GallicaIndexer.LOCK_FILE);

// should not arrive
if (baseDir.isFile() && !baseDir.delete()) {
    throw new ServletException("Fichiers, droits, impossible de supprimer cette base.");
}
if (!baseDir.exists() && !baseDir.mkdirs()) {
    throw new ServletException("Fichiers, droits, impossible de créer cette base.");
}
// already locked, send redirection to server, Rooter will do better job
if (lockFile.exists()) {
    request.getRequestDispatcher("").forward(request, response);
}
String key = baseDir.getCanonicalPath().toString();
final Map<String, Future<String>> futures = (Map<String, Future<String>>)servletContext.getAttribute(Rooter.FUTURES);
Future<String> future = futures.get(key);
if (future != null) {
    if (!future.isDone()) {
        logger.log(Level.WARNING, String.format("%s tâche en cours", key));
    }
}
String value = request.getParameter(Rooter.ARKS);
String[] arks = value.split("\\s+");
String label = request.getParameter("label");
if (label == null || "".equals(label.trim())) label = base;
Callable<String> task = new GallicaIndexer(label, arks, baseDir);
final ExecutorService pool = (ExecutorService)servletContext.getAttribute(Rooter.POOL);
pool.submit(task);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chargement — Gallicobvie</title>
    <link href="../static/obvie.css" rel="stylesheet"/>
</head>
<body>
    <div class="landing">
        <h1><a href="."><%=label%></a>, chargement</h1>
        <div class="row">
            <div>
                <h2>Arks en cours d’indexation</h2>
                <ul>
                <%
for (String ark: arks) {
    final String href = String.format("https://gallica.bnf.fr/ark:/12148/%s", ark);
    out.println(String.format("<li><a target=\"_blank\" href=\"%s\">%s</a></li>", href, ark));
}
                %>
                </ul>
            </div>
            <div>
                <h2>Avancement</h2>
                <iframe id="report" src="report.jsp"></iframe>
            </div>
        </div>
    </div>
    <script>
const reloadReport = window.setInterval(report, 10000);
function report() {
    document.getElementById('report').contentWindow.location.reload(true);
}
    </script>
</body>
</html>