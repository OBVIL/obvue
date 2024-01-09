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
    <title>Arks — Gallicobvie</title>
    <link href="<%=hrefContext%>static/obvie.css" rel="stylesheet"/>
</head>
<body>
<div class="landing">
    <a class="logo" href="<%=hrefContext%>" title="Créer un nouveau corpus"><img alt="Nouvelle base" src="<%=hrefContext%>static/img/obvie_50.png"/></a>
    <h1>Nouvelle base : <a href="."><%=base%></a></h1>
    <p>Notez bien le lien de cette base, elle sera supprimée après <%=baselife%> jours sans utilisation.</p>
    <p>Proposez une liste d’identifiants Gallica (arks) pour composer votre corpus de textes. 
    Le nombre est pour l’instant limité à 5 textes pour ce prototype.
    </p>
    <form method="post">
        <div class="table center">
            <div class="tr">
                <div class="th">
                    <label for="label">Nom du corpus</label>
                </div>
                <div class="td">
                    <input name="label" size="15"/>
                </div>
            </div>
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
            <div class="tr">
                <div class="th">
                    <label>Série d’arks Gallica,<br/> 1 par ligne</label>
                </div>
                <div class="td">
        <textarea rows="5" cols="15" name="<%=Rooter.ARKS%>">
bpt6k54805
bpt6k5482s
bpt6k54833
bpt6k5484d
bpt6k5485q
        </textarea>
                </div>
            </div>
            <div class="tr">
                <div class="th">
                </div>
                <div class="td">
                    <button>Indexer</button>
                </div>
            </div>
        </div>
    </form>
</div>
</body>
</html>
<%
// */
%>