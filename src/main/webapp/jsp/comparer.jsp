<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp"%>
<%
final String hrefContext = (String)request.getAttribute(Rooter.HREF_CONTEXT);

// parameters
String id1 = tools.getString("leftid", null);
int docId1 = tools.getInt("leftdocid", -1);
String id2 = tools.getString("rightid", null);
int docId2 = tools.getInt("rightdocid", -1);
String q = tools.getString("q", null);
int start = tools.getInt("start", -1); // to come back to main window

// global variables
Corpus corpus = (Corpus) session.getAttribute(corpusKey);

String url1;
String ref = "";
if (id1 != null) { // doc by id requested
    url1 = "compdoc?" + "id=" + id1;
    ref = "&amp;refid=" + id1;
} else if (docId1 >= 0) { // doc by docid requested
    url1 = "compdoc?" + "docid=" + docId1;
    ref = "&amp;refdocid=" + docId1;
} else if (q != null) { // query
    url1 = "meta?" + "q=" + q;
} else { // query
    url1 = "meta";
}

String url2;
if (id2 != null) { // doc by id requested
    url2 = "compdoc?" + "id=" + id2 + ref;
} else if (docId2 >= 0) { // doc by docid requested
    url2 = "compdoc?" + "docid=" + docId2 + ref;
} else if (id1 != null) { // reference document for list or hilite
    url2 = "meta?refid=" + id1;
} else if (docId1 >= 0) { // reference document for list or hilite
    url2 = "meta?refdocid=" + docId1;
} else { // help
    url2 = "../static/doc/index.html";
}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Comparer, <%=(corpus != null) ? JspTools.escape(corpus.name()) + ", " : ""%><%=alix.props.get("label")%>
    [Obvie]
</title>
<link rel="stylesheet" type="text/css" href="../static/obvie.css" />
<script src="../static/js/common.js">
    //
</script>
<style>
body, html {
    height: 100%;
    margin: 0;
    padding: 0;
}

#cont {
    position: relative;
    background-color: red;
    height: 100%;
}
</style>
</head>
<body class="comparer">
    <header id="header" class="header_desk">
      <div class="left">
        <a class="logo gallica" href="https://gallica.bnf.fr/">
          <img src="<%=hrefContext%>static/img/gallica_logo.svg" alt="ObTIC" height="40"/>
        </a>
        <div class="base"><a href=".">Corpus : <em><%=alix.props.get("label")%></em></a> <%
 if (corpus != null) {
     String name = corpus.name();
     out.println("<mark><a title=\"Déselectionner ce corpus\" href=\"?corpus=new&amp;q=" + JspTools.escUrl(q)
     + "\">🗙</a>  " + name + "</mark>");

 }
 %></div>
        </div>
        <form id="qform" name="qform" action=".">
            <a href="." class="reset" title="Annuler les recherches en cours"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960" width="24" height="24"><path d="M480-160q-134 0-227-93t-93-227q0-134 93-227t227-93q69 0 132 28.5T720-690v-110h80v280H520v-80h168q-32-56-87.5-88T480-720q-100 0-170 70t-70 170q0 100 70 170t170 70q77 0 139-44t87-116h84q-28 106-114 173t-196 67Z"/></svg></a>
            <input type="hidden"
                name="start" value="<%=((start > 0) ? "" + start : "")%>" />
            <input type="hidden" name="hpp" /> <input id="q" name="q"
                autocomplete="off" value="<%=JspTools.escape(q)%>"
                oninput="this.form['start'].value=''; this.form['hpp'].value=''" />
            <button type="submit" name="send" tabindex="-1" class="magnify"><svg width="24" height="24"><path d="M9 2a7 7 0 0 0 0 14 7 7 0 0 0 4.6-1.7l.4.4V16l6 6 2-2-6-6h-1.3l-.4-.4A7 7 0 0 0 9 2zm0 2a5 5 0 0 1 5 5 5 5 0 0 1-5 5 5 5 0 0 1-5-5 5 5 0 0 1 5-5z"/></svg></button>
            <div id="tabs">
                <button name="view" value="corpus">Corpus</button>
                <button name="view" value="cloud">Nuage</button>
                <button name="view" value="reseau">Réseau</a>
                <button name="view" value="freqs">Fréquences</button>
                <button name="view" value="snip">Extraits</button>
                <button name="view" value="kwic">Concordance</button>
                <a class="here" href="">Comparer</a>
                <a class="help" href="../static/aide.html" target="aide">Aide</a>
            </div>
        </form>
      <a class="logo obvie" href="<%=hrefContext%>" title="Annuler les recherches en cours"><img align="middle" alt="Nouveau corpus" src="<%=hrefContext%>static/img/obvie_50b.png"/></a>
    </header>
    <div id="win">
        <iframe id="left" name="left" src="<%=url1%>"> </iframe>
        <iframe id="right" name="right" src="<%=url2%>"> </iframe>
    </div>
    <script src="../static/js/comparer.js">
                    //
                </script>
</body>
</html>
