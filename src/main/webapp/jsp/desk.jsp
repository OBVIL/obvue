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
    <header id="header">
      <span class="base"><a href=".">Corpus : <em><%=alix.props.get("label")%></em></a> <%
   if (corpus != null) {
     String name = corpus.name();
     out.println("<mark><a class=\"xred\" title=\"Supprimer la sélection\" href=\"?corpus=new&amp;q="+JspTools.escUrl(q)+"\">🗙</a>  "+name+"</mark>");
   }
 %></span>
      <a class="logo" href="../" title="Liste des collections de cet installation."><img alt="Obvie app" src="../static/img/obvie_50.png"/></a>
      <form id="qform" name="qform" onsubmit="return dispatch(this)" target="page" action="<%=view%>">
        <a href="." class="reset" title="Annuler les recherches en cours">⟲</a>
        <input type="hidden" name="start" value="<%= ((start > 0)?""+start:"") %>"/>
        <input type="hidden" name="hpp"/>
        <input type="hidden" name="leftid"/>
        <input id="q" name="q" autocomplete="off" autofocus="true" value="<%=JspTools.escape(q)%>"
          oninput="this.form['start'].value=''; this.form['hpp'].value=''"
        />
        <button type="submit" name="send" tabindex="-1" class="magnify">⚲</button>
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
      <a class="hn" href="https://www.huma-num.fr/annuaire-des-sites-web" target="_blank">
        <img title="Hébergé par Huma-Num" src="../static/img/hn.png" align="right"/>
      </a>
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
