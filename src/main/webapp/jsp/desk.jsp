<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="prelude.jsp" %>
<%

// params
String[] checks = request.getParameterValues("book");
String json = tools.getString("json", null);
String q = tools.getString("q", null);
String id = tools.getString("id", null);
String view = tools.getString("view", null);
int start = tools.getInt("start", -1);
final boolean expression = tools.getBoolean("expression", false);

String url;

// pars
String pars = "";
if (q != null) {
  pars += "q=" + JspTools.escUrl(q);
  if (start > 1) pars += "&amp;start="+start;
  if (expression) pars += "&amp;expression=true";
}
if (id != null) {
  if (pars.length() > 0) pars += "&amp;";
  pars += "id="+id;
}

if (pars.length() > 0) pars = "?" + pars;

if (view != null) { // client knows what he wants, give it
  url = view + pars;
}
else if (id != null) {
  view = "doc";
  url = view + pars;
}
else if (q != null) {
  view = "kwic";
  url = view + pars;
}
else {
  view = "corpus";
  url = view;
}


//prepare a corpus ?
String js = "";
Corpus corpus = null;
if ("POST".equalsIgnoreCase(request.getMethod())) {
  // handle paramaters to change the corpus
  String name = tools.getString("name", null);
  String desc = tools.getString("desc", null);
  if (name == null) name = "Ma sélection";
  if (checks != null) {
    corpus = new Corpus(alix, Names.ALIX_BOOKID, name, desc);
    corpus.add(checks);
    session.setAttribute(corpusKey, corpus);
    json = corpus.json();
    // corpus has been modified, store on client
    js += "corpusStore(\""+name+"\", \""+desc+"\", '"+json+"');\n";
  }
  //json send, client wants to load a new corpus
  else if (json != null) {
   corpus = new Corpus(alix, Names.ALIX_BOOKID, json);
   name = corpus.name();
   desc = corpus.desc();
   session.setAttribute(corpusKey, corpus);
  }
}
else if ("new".equals(tools.getString("corpus", null))) {
  session.setAttribute(corpusKey, null);
}
corpus = (Corpus)session.getAttribute(corpusKey);
final String hrefContext = (String)request.getAttribute(Rooter.HREF_CONTEXT);


%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8"/>
    <title><%= (corpus != null) ? JspTools.escape(corpus.name())+", " : "" %><%=alix.props.get("label")%> [Obvie]</title>
    <link rel="preconnect" href="https://fonts.gstatic.com">
    <link href="https://fonts.googleapis.com/css2?family=Lato&amp;display=swap" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="../static/obvie.css"/>
    <script> const base = "<%=base%>"; </script> <%-- give code of the text base for all further js  --%>
    <script src="../static/vendor/split.js">//</script>
    <script src="../static/js/common.js">//</script>
    <script src="../static/js/corpora.js">//</script>
    <script>
       <%=js %>
    </script>
  </head>
  <body class="split">
    <header id="header" class="header_desk">
      <div class="left">
        <a class="logo gallica" href="https://gallica.bnf.fr/">
          <img src="<%=hrefContext%>static/img/gallica_logo.svg" alt="ObTIC" height="40"/>
        </a>
      
        <span class="base"><a href=".">Corpus : <em><%=alix.props.get("label")%></em></a> <%
   if (corpus != null) {
     String name = corpus.name();
     out.println("<mark><a class=\"xred\" title=\"Supprimer la sélection\" href=\"?corpus=new&amp;q="+JspTools.escUrl(q)+"\">🗙</a>  "+name+"</mark>");
   }%>
        </span>
      </div>
      <form id="qform" name="qform" onsubmit="return dispatch(this)" target="page" action="<%=view%>">
        <a href="." class="reset" title="Annuler les recherches en cours"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960" width="24" height="24"><path d="M480-160q-134 0-227-93t-93-227q0-134 93-227t227-93q69 0 132 28.5T720-690v-110h80v280H520v-80h168q-32-56-87.5-88T480-720q-100 0-170 70t-70 170q0 100 70 170t170 70q77 0 139-44t87-116h84q-28 106-114 173t-196 67Z"/></svg></a>
        <input type="hidden" name="start" value="<%= ((start > 0)?""+start:"") %>"/>
        <input type="hidden" name="hpp"/>
        <input type="hidden" name="leftid"/>
        <input id="q" name="q" autocomplete="off" autofocus="true" value="<%=JspTools.escape(q)%>"
          oninput="this.form['start'].value=''; this.form['hpp'].value=''"
        />
        <button type="submit" name="send" tabindex="-1" class="magnify"><svg width="24" height="24"><path d="M9 2a7 7 0 0 0 0 14 7 7 0 0 0 4.6-1.7l.4.4V16l6 6 2-2-6-6h-1.3l-.4-.4A7 7 0 0 0 9 2zm0 2a5 5 0 0 1 5 5 5 5 0 0 1-5 5 5 5 0 0 1-5-5 5 5 0 0 1 5-5z"/></svg></button>
        <div id="tabs">
          <a href="corpus" target="page">Corpus</a>
          <a href="cloud" target="page">Nuage</a>
          <a href="reseau" target="page">Réseau</a>
          <a href="freqs" target="page">Fréquences</a>
          <a href="snip" target="page">Extraits</a>
          <a href="kwic" target="page">Concordance</a>
          <a href="doc" target="page">Document</a>
          <button type="submit" id="comparer" style="display: none" onclick="this.form.target='_self'; this.form.action = 'comparer'; this.form.submit()">Comparer</button>
          <a class="help" href="../static/aide.html" target="aide">Aide</a>
        </div>
      </form>
      <a class="logo obvie" href="<%=hrefContext%>"><img align="middle" alt="Nouveau corpus" src="<%=hrefContext%>static/img/obvie_50b.png"/></a>

      <!-- 
      <a class="hn" href="https://www.huma-num.fr/annuaire-des-sites-web" target="_blank">
        <img title="Hébergé par Huma-Num" src="../static/img/hn.png" align="right"/>
      </a>
       -->
    </header>
    <div id="win">
      <div id="aside">
        <iframe id="panel" name="panel" src="facet<%= pars %>">
        </iframe>
      </div>
      <div id="main">
        <div id="body">
          <iframe name="page" id="page" src="<%= url %>">
          </iframe>
        </div>
        <footer id="footer">
          <iframe id="chrono" name="chrono" src="chrono<%= pars %>">
          </iframe>
         </footer>
      </div>
    </div>
    <script src="../static/js/desk.js">//</script>
  </body>
</html>
