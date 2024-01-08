<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.GallicaIndexer"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter"%>
<%
File dataDir = (File)pageContext.getAttribute(Rooter.DATADIR);
String base = (String)pageContext.getAttribute(Rooter.BASE);
File baseDir = new File(dataDir, base);
//already locked, send redirection to server, Rooter will do better job
File lockFile = new File(baseDir, GallicaIndexer.LOCK_FILE);
if (lockFile.exists()) {
 request.getRequestDispatcher("").forward(request, response);
}

%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Charger des arks — Gallicobvie</title>
    <link href="../static/obvie.css" rel="stylesheet"/>
</head>
<body>
    <h1>Nouvelle base : <a href="."><%=base%></a></h1>
    <p>Notez bien le lien de cette base, elle sera supprimée après <%=baselife%> jours.</p>
    <form method="post">
        <label>Nom du corpus</label>
        <input name="name"/>
        <label>Description</label>
        <input name="desc"/>
        <label>Série d’arks Gallica, 1 par ligne</label>
        <textarea name="<%=Rooter.ARKS%>">
bpt6k54805
bpt6k5482s
bpt6k54833
bpt6k5484d
bpt6k5485q
        </textarea>
    </form>
</body>
</html>