<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="java.util.Arrays"%>
<%@ page import="java.util.Enumeration"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.GallicaIndexer"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter"%>
<%
final ServletContext servletContext = pageContext.getServletContext();
final File dataDir = (File)servletContext.getAttribute(Rooter.DATADIR);
final String base = (String)request.getAttribute(Rooter.BASE);
final File baseDir = new File(dataDir, base);
final File lockFile = new File(baseDir, GallicaIndexer.LOCK_FILE);

//already locked, send redirection to server, Rooter will do better job
if (lockFile.exists()) {
 request.getRequestDispatcher("").forward(request, response);
}
final int baselife = (Integer)servletContext.getAttribute(Rooter.BASELIFE);
final String hrefContext = (String)request.getAttribute(Rooter.HREF_CONTEXT);

%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Arks, Obvie-Gallica</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cantarell&family=Lato:ital,wght@0,400;0,700;1,400;1,700&family=Noto+Sans+Display&display=swap" rel="stylesheet">
    <link href="<%=hrefContext%>static/obvie.css" rel="stylesheet"/>
</head>
<body class="win">
    <%@ include file="header.jsp"%>
<div class="landing">
    
    <form method="post">
        <table>
            <caption><h1>Nouvelle base : <a href="."><%=base%></a></h1></caption>
            <tr>
                <th style="white-space: nowrap;" class="right">
                    <label for="label">Nom du corpus</label>
                </th>
                <td>
                    <input name="label" size="15"/>
                </td>
                <td rowspan="3" style="width: 20rem; padding: 1rem;">
                    <p>Notez bien le lien de cette base, elle sera supprimée après <%=baselife%> jours sans utilisation.</p>
                    <p>Proposez une liste d’identifiants Gallica (arks) pour composer votre corpus de textes. 
                    Le nombre est pour l’instant limité à 5 textes pour ce prototype.
                    </p>
                </td>
            </tr>
            <!-- 
            <div class="tr">
                <div class="th">
                    <label>Description (optionnel)</label>
                </div>
                <div class="td">
                    <input name="desc" size="50"/>
                </div>
            </div>
             -->
            <tr>
                <th class="right">
                    <label>Série d’arks Gallica,<br/> 1 par ligne</label>
                </th>
                <td>
        <textarea rows="10" cols="15" name="<%=Rooter.ARKS%>">
bpt6k54805
bpt6k5482s
bpt6k54833
bpt6k5484d
bpt6k5485q
        </textarea>
                </td>
            </tr>
            <tr>
                <td></td>
                <td>
                    <button>Indexer</button>
                </td>
            </tr>
        </table>
    </form>
</div>
<%@ include file="footer.jsp"%>
</body>
</html>
