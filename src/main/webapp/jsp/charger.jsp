<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="java.util.concurrent.Future" %>
<%@ page import="java.util.logging.Logger" %>
<%@ page import="java.util.Map" %>
<%@ page import="fr.sorbonne_universite.obtic.obvie.GallicaIndexer"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter"%>
<%! @SuppressWarnings("unchecked") %>
<%
Logger logger = Logger.getLogger(this.getClass().getName());
ServletContext servletContext = pageContext.getServletContext();
File dataDir = (File)pageContext.getAttribute(Rooter.DATADIR);
String base = (String)pageContext.getAttribute(Rooter.BASE);
File baseDir = new File(dataDir, base);
// should not arrive
if (baseDir.isFile() && !baseDir.delete()) {
    throw new ServletException("Fichiers, droits, impossible de supprimer cette base.");
}
if (!baseDir.exists() && !baseDir.mkdirs()) {
    throw new ServletException("Fichiers, droits, impossible de créer cette base.");
}
// already locked, send redirection to server, Rooter will do better job
File lockFile = new File(baseDir, GallicaIndexer.LOCK_FILE);
if (lockFile.exists()) {
    request.getRequestDispatcher("").forward(request, response);
}
String value = request.getParameter(Rooter.ARKS);
String[] arks = value.split("\\s+");
String key = baseDir.getCanonicalPath().toString();
Map<String, Future<String>> futures = (Map<String, Future<String>>)servletContext.getAttribute(Rooter.FUTURES);
// Future<String> future = futures
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Charger des arks — Gallicobvie</title>
    <link href="../static/obvie.css" rel="stylesheet"/>
</head>
<body>
    <article class="landing">
        
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
            <div>Update des tâches en cours</div>
        </div>
    </article>
</body>
</html>