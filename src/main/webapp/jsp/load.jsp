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
final String hrefContext = (String)request.getAttribute(Rooter.HREF_CONTEXT);

Logger logger = Logger.getLogger(this.getClass().getName());
final ServletContext servletContext = pageContext.getServletContext();
final File dataDir = (File)servletContext.getAttribute(Rooter.DATADIR);
final String base = (String)request.getAttribute(Rooter.BASE);
final File baseDir = new File(dataDir, base);
final File lockFile = new File(baseDir, GallicaIndexer.LOCK_FILE);
final int baselife = (Integer)servletContext.getAttribute(Rooter.BASELIFE);

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
    <title>Chargement — Obvie-Gallica</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cantarell&family=Lato:ital,wght@0,400;0,700;1,400;1,700&family=Noto+Sans+Display&display=swap" rel="stylesheet">
    <link href="<%=hrefContext%>static/obvie.css" rel="stylesheet"/>
</head>
<body class="win">
    <%@ include file="header.jsp"%>
    <div class="landing">
        <h1><a href="."><%=label%></a> — chargement</h1>
        <p>Notez bien le lien de cette base, elle sera supprimée après <%=baselife%> jours sans utilisation.</p>
        <div><b>Textes demandés :</b>
        <%
String sep = "";
for (String ark: arks) {
    final String href = String.format("https://gallica.bnf.fr/ark:/12148/%s", ark);
    out.print(String.format("%s<a target=\"_blank\" href=\"%s.texteBrut\">%s</a>", sep, href, ark));
    sep = ", ";
}
out.print(".");
            %>
        </div>
        <iframe style="width: 100%; height: 25rem;" id="report" src="report"></iframe>
    </div>
    <%@ include file="footer.jsp"%>
    <script>
const reloadReport = window.setInterval(report, 10000);
function report() {
    document.getElementById('report').contentWindow.location.reload(true);
}
    </script>
</body>
</html>