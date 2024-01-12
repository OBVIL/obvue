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
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cantarell&family=Lato:ital,wght@0,400;0,700;1,400;1,700&family=Noto+Sans+Display&display=swap" rel="stylesheet">
    <title>Obvie-Gallica, accueil</title>
    <link href="static/obvie.css" rel="stylesheet"/>
</head>
<body class="win">
    <%@ include file="header.jsp"%>
    <div class="landing">
        <ul>
            <li><a href="https://obtic.huma-num.fr/obvie/">Obvie</a> : un moteur avancé de fouille de textes (ObTiC)</li>
            <li><a href="https://gallica.bnf.fr/">Gallica</a> : la Bibliothèque numérique de la Bibliothèque nationale de France (BnF)</li>
            <li><a href=".">Obvie-Gallica</a> : explorer son corpus Obvie avec des textes Gallica</li>
        </ul>
        <div class="buts">
            <a class="button" href="<%=(request.getContextPath() + "/" + name + "/") %>">Explorer un nouveau corpus</a>
        </div>
    </div>
    <%@ include file="footer.jsp"%>
</body>
</html>