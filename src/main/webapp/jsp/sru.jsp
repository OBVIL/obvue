<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%
final String hrefContext = (String)request.getAttribute(Rooter.HREF_CONTEXT);

/*
    https://api.bnf.fr/fr/node/222
   https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&version=1.2&startRecord=0&maximumRecords=50&page=1&collapsing=false&exactSearch=true&query=(ocr.quality all "Texte disponible") and (dc.creator all "Ponson du Terrail")

https://gallica.bnf.fr/SRU?startRecord=0&maximumRecords=50&operation=searchRetrieve&exactSearch=true&collapsing=false&version=1.2&query=(ocr.quality all "Texte disponible") and (dc.creator all "Ponson du Terrail" and (gallicapublication_date>="1870" and gallicapublication_date<="1890"))
    
   */


%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SRU, recherche dans le catalogue Gallica, Gallica-Obvie</title>
    <link href="<%=hrefContext %>static/obvie.css" rel="stylesheet"/>
</head>
<body>
    <form>
        <div>
            <input name="dc.creator"/>
        </div>
        <div>
            <input name="gallicapublication_date" class="date"/>
            <input name="gallicapublication_date" class="date"/>
        </div>
    </form>
</body>
</html>