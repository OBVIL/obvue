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
String baseHref = request.getContextPath() + '/';
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
            <h1>Gallicobvie</h1>
            <ul>
                <li><a href="https://obtic.huma-num.fr/obvie/">Obvie</a> : un moteur avancé de fouille de textes (ObTiC)</li>
                <li><a href="https://gallica.bnf.fr/">Gallica</a> : la Bibliothèque numérique de la Bibliothèque nationale de France (BnF)</li>
                <li><a href=".">Gallicobvie</a> : construire son corpus de textes avec Gallica et l’explorer avec Obvie</li>
            </ul>
                <a class="button" href="<%=(baseHref + name) %>">Créer un nouveau corpus</a>
            </form>
        </div>
    </article>
</body>
</html>