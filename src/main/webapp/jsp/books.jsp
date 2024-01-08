<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="prelude.jsp"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.FieldFacet"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.FieldInt"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.TermList"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.FormEnum"%>
<%@ page import="org.apache.lucene.index.FieldInfos"%>
<%@ page import="org.apache.lucene.index.FieldInfo"%>
<%!final static HashSet<String> FIELDS = new HashSet<String>(
            Arrays.asList(new String[]{Names.ALIX_BOOKID, "byline", "year", "title"}));
static Sort SORT = new Sort(new SortField("author1", SortField.Type.STRING),
            new SortField("year", SortField.Type.INT));%>
<%
// params for this page
String q = tools.getString("q", null);

// global variables
Corpus corpus = (Corpus) session.getAttribute(corpusKey);
Set<String> bookids = null;
if (corpus != null) {
    bookids = corpus.books();
}
FieldFacet facet = alix.fieldFacet(Names.ALIX_BOOKID);
FieldText ftext = alix.fieldText(TEXT);

FieldInt years = null;
try {
    years = alix.fieldInt(YEAR); // to get min() max() year
}
catch (Exception e) {
}
String[] qterms = alix.tokenize(q, TEXT);
final boolean score = (qterms != null && qterms.length > 0);

// get an order for terms
OptionFacetSort fallback = OptionFacetSort.alpha;
if (score) {
    fallback = OptionFacetSort.score;
}
OptionFacetSort sort = (OptionFacetSort) tools.getEnum("ord", fallback, Cookies.corpusSort);


BitSet bits = bits(alix, corpus, q);
// out.println()

FormEnum results = facet.forms(ftext, bits, qterms, OptionDistrib.G); // .topTerms(bits, qTerms, null);
boolean author = (alix.info("author") != null);

%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Corpus [Obvie]</title>
        <link href="../static/vendor/sortable.css" rel="stylesheet" />
        <link href="../static/obvie.css" rel="stylesheet" />
        <script src="../static/js/common.js">//</script>
        <script type="text/javascript">
//give code of texts base to further Javascript
const base = "<%=base%>"; 
        </script>
        <script src="../static/js/corpus.js">//</script>
    </head>
    <body class="corpus">
        <main>
            <details id="filter">
                <summary>Filtres</summary>
                <% if (author) { %>
                <label for="author">Auteur</label>
                <input id="author" name="author" autocomplete="off"
                    list="author-data" size="50" type="text"
                    onclick="select()" placeholder="Nom, Prénom" />
                <%}%>
                <% if (years != null ) { %>
                <br />
                <label for="start">Dates</label>
                <input id="start" name="start" type="number"
                    min="<%=years.min()%>" max="<%=years.max()%>"
                    placeholder="Début" class="year" />
                <input id="end" name="end" type="number"
                    min="<%=years.min()%>" max="<%=years.max()%>"
                    placeholder="Fin" class="year" />
                <%}%>
                <br />
                <label for="title">Titre</label>
                <input id="title" name="title" autocomplete="off"
                    list="title-data" type="text" size="50"
                    onclick="select()" placeholder="Chercher un titre" />
            </details>
            <form method="post" id="corpus" target="_top" action=".?view=corpus">
                <table class="sortable" id="bib">
                    <caption>
                        <div class="flex">
                            <div style="float: left">
<input type="hidden" name="q" value="<%=JspTools.escape(q)%>" />
<%
if (score) {
    out.println(results.freqAll() + " occurrences trouvées dans " + results.hitsAll() + " chapitres");
}
else {
    out.println(((bits != null) ? bits.cardinality() : facet.docs()) + " chapitres");
}
%>
                            </div>
                            <div style="text-align:right">
<input style="float: right;" type="text" size="10"
    id="name" name="name"
    value="<%=(corpus != null) ? JspTools.escape(corpus.name()) : ""%>"
    title="Donner un nom à cette sélection"
    placeholder="Nommer cette séelection ?"
    oninvalid="this.setCustomValidity('Un nom est nécessaire pour enregistrer votre sélection.')"
    oninput="this.setCustomValidity('')"
    required="required" />
<button name="save"
    type="submit">Enregistrer</button>
                            </div>
                        </div>
                    </caption>
                <thead>
                    <tr>
                        <th class="checkbox"><input id="checkall" <%= (score)?" checked=\"checked\"":"" %>
                            type="checkbox"
                            title="Sélectionner/déselectionner les lignes visibles" /></th>
                        <th class="author">auteur</th>
                        <th class="title">titre</th>
                        <%
if (years != null) {
    out.println("<th class=\"year\">date</th>");
}
if (score) {
    out.println("<th class=\"occs\" title=\"Occurrences\">occs</th>");
    out.println("<th class=\"docs\" title=\"Chapitres\">chaps.</th>");
    out.println("<th class=\"score\">pertinence</th>");
}
else {
    out.println("<th class=\"length\" title=\"Taille en mots\">taille</th>");
    out.println("<th class=\"docs\" title=\"Chapitres\">chaps.</th>");
}
                        %>
                        
                    </tr>
                </thead>
                <tbody>
<%
FormEnum.Order order;
switch (sort) {
    case alpha :
        order = FormEnum.Order.ALPHA;
        break;
    case score :
        if (score) {
            order = FormEnum.Order.SCORE;
        }
        else {
            order = FormEnum.Order.ALPHA;
        }
        break;
    case freq :
        if (score) {
            order = FormEnum.Order.OCCS;
        }
        else {
            order = FormEnum.Order.ALPHA;
        }
        break;
    default :
        order = FormEnum.Order.ALPHA;
}
results.sort(order);

// Hack to use facet as a navigator in results
// get and cache results in facet order, find a index 
TopDocs topDocs = getTopDocs(pageContext, alix, corpus, q, OptionSort.author);
int[] nos = facet.nos(topDocs);
results.setNos(nos);

while (results.hasNext()) {
    results.next();
    String bookid = results.form();
    // String bookid = doc.get(Alix.BOOKID);
    Document doc = reader.document(alix.getDocId(bookid), FIELDS);
    // for results, do not diplay not relevant results
    // if (score && results.occs() == 0) continue;

    out.println("<tr>");
    // checkbox
    out.println("  <td class=\"checkbox\">");
    out.print("    <input type=\"checkbox\" name=\"book\" id=\"" + bookid + "\" value=\"" + bookid + "\"");
    if (bookids != null && bookids.contains(bookid))
        out.print(" checked=\"checked\"");
    if (score)
        out.print(" checked=\"checked\"");
    out.println(" />");
    out.println("  </td>");
    out.print("  <td class=\"author\">");
    out.print("<label for=\"" + bookid + "\">");
    String byline = doc.get("byline");
    if (byline != null)
        out.print(byline);
    out.print("</label>");
    out.println("</td>");
    out.println("  <td class=\"title\">");
    int n = results.no();
    String href;
    // hpp?
    if (score)
        href = "kwic?sort=author&amp;q=" + JspTools.escUrl(q) + "&amp;start=" + (n + 1);
    else
        href = "doc?sort=author&amp;start=" + (n + 1);
    out.print("<a href=\"" + href + "\">");
    // out.println("<a href=\"kwic?sort="+facetField+"&amp;q="+q+"&start="+(n+1)+"&amp;hpp="+hits+"\">");
    out.print(doc.get("title"));
    out.println("</a>");
    out.println("  </td>");
    String year = doc.get("year");
    if (year == null) year ="";
    if (years != null) {
        out.println("  <td class=\"year\">" + year + "</td>");
    }
    if (score) {
        String scoreString;
        double scoreDouble = results.score();
        if (scoreDouble ==  Double.NEGATIVE_INFINITY || scoreDouble ==  Double.POSITIVE_INFINITY) {
            scoreString = "" + scoreDouble;
        }
        else {
            scoreString = dfScoreFr.format(results.score());
        }

        out.println("  <td class=\"occs num\">" + results.freq() + "</td>");
        out.println("  <td class=\"docs num\">" + results.hits() + "</td>");
        out.println("  <td class=\"score num\">" + dfScoreFr.format(results.score()) + "</td>");
    }
    else {
        out.println("  <td class=\"length num\">" + dfint.format(results.occs()) + "</td>");
        out.println("  <td class=\"docs num\">" + results.docs() + "</td>");
    }
    out.println("</tr>");
}
// TermQuery filterQuery = null;
// put metas
%>
                    </tbody>
                </table>
            </form>
        </main>

        <script src="../static/vendor/sortable.js">//</script>
    <%
    // Loop on metadata fields to provide lists for suggestion
    for (String field : new String[]{"author", "title"}) {
        if (alix.info(field) == null) {
            continue;
        }
        facet = alix.fieldFacet(field);
        results = facet.forms();
        out.println("<datalist id=\"" + field + "-data\">");
        results.sort(FormEnum.Order.ALPHA);
        while (results.hasNext()) {
            results.next();
            // long weight = facetEnum.weight();
            out.println("  <option value=\"" + JspTools.escape(results.form()) + "\"/>");
        }
        out.println("</datalist>");
    }
    %>
        <a href="#" id="gotop">▲</a>
        <script>
bottomLoad();
<%if (corpus != null) out.println("showSelected();");%>
                    
        </script>
    </body>
</html>
