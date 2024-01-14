<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
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
// Not locked, send redirection to server, Rooter will do better job
final File lockFile = new File(baseDir, GallicaIndexer.LOCK_FILE);
if (!lockFile.exists()) {
    request.getRequestDispatcher("").forward(request, response);
}
// properties
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Indexation en cours — Gallicobvie</title>
    <link href="../static/obvie.css" rel="stylesheet"/>
</head>
<body class="win">
    <%@ include file="header.jsp"%>
    <article class="landing">
        <h1><%=base %>, indexation en cours</h1>
        <p>                                                                                                                      </p>
        <iframe style="width: 100%; height: 25rem;" id="report" src="report"></iframe>
    </article>
    <%@ include file="footer.jsp"%>
    <script>
const reloadReport = window.setInterval(report, 10000);
function report() {
    document.getElementById('report').contentWindow.location.reload(true);
}
    </script>
</body>
</html>