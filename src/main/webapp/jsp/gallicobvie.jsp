<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter"%>
<%@ page import="com.github.oeuvres.alix.util.RandomName"%>
<%
File dataDir = (File)pageContext.getAttribute(Rooter.DATADIR);
String name = RandomName.name(10);
int i = 0;
while (new File(dataDir, name).exists()) {
    if (i++ > 10) {
        throw new ServletException("[dev] 10 essais pour trouver un nom de base libre");
    }
    name = RandomName.name(10);
}
final String hrefContext = (String)request.getAttribute(Rooter.HREF_CONTEXT);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Gallicobvie, accueil</title>
    <link href="static/obvie.css" rel="stylesheet"/>
</head>
<body>
    <article class="chapter">
        <div class="landing">
            <a class="logo" href="<%=hrefContext%>" title="Créer un nouveau corpus"><img alt="Nouvelle base" src="static/img/obvie_50.png"/></a>
            <h1>Gallicobvie</h1>
            <ul>
                <li><a href="https://obtic.huma-num.fr/obvie/">Obvie</a> : un moteur avancé de fouille de textes (ObTiC)</li>
                <li><a href="https://gallica.bnf.fr/">Gallica</a> : la Bibliothèque numérique de la Bibliothèque nationale de France (BnF)</li>
                <li><a href=".">Gallicobvie</a> : construire son corpus de textes avec Gallica et l’explorer avec Obvie</li>
            </ul>
            <div class="buts">
                <a class="but" href="<%=(request.getContextPath() + "/" + name + "/") %>">Enregistrer un nouveau corpus</a>
            </div>
        </div>
    </article>
</body>
</html>