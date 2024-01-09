<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.BufferedReader"%>
<%@ page import="java.io.File"%>
<%@ page import="java.nio.charset.StandardCharsets"%>
<%@ page import="java.nio.file.Files"%>
<%@ page import="java.nio.file.Paths"%>
<%@ page import="java.util.Arrays"%>
<%@ page import="java.util.Enumeration"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.GallicaIndexer"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter"%>
<%
final ServletContext servletContext = pageContext.getServletContext();
final File dataDir = (File)servletContext.getAttribute(Rooter.DATADIR);
final String base = (String)request.getAttribute(Rooter.BASE);
final File baseDir = new File(dataDir, base);
final File reportFile = new File(baseDir, GallicaIndexer.REPORT_FILE);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Téléchargements, avancement  — Gallicobvie</title>
</head>
<body>
    <div class="landing">
        <pre><%
if (reportFile.exists()) {
    BufferedReader reader = Files.newBufferedReader(reportFile.toPath(), StandardCharsets.UTF_8);
    String line;
    while((line = reader.readLine())!= null){
        out.println(line);
    }
}

        %></pre>
    </div>
</body>
</html>
