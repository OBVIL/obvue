<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.GallicaIndexer"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter"%>
<%
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
// Now, lock, atomic op
lockFile.createNewFile();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Charger des arks — Gallicobvie</title>
    <link href="../static/obvie.css" rel="stylesheet"/>
</head>
<body>
    <article class="chapter">
        <div class="row">
            <div>List des arks </div>
            <div>Update des tâches en cours</div>
        </div>
    </article>
</body>
</html>