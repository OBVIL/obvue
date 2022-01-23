<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="prelude.jsp"%>
<%@ page import="alix.lucene.search.FieldFacet"%>
<%@ page import="alix.lucene.search.FieldInt"%>
<%@ page import="alix.lucene.search.TermList"%>
<%@ page import="alix.lucene.search.FormEnum"%>
<%!
final static HashSet<String> FIELDS = new HashSet<String>(
            Arrays.asList(new String[]{Alix.BOOKID, "byline", "year", "title"}));
static Sort SORT = new Sort(new SortField("author1", SortField.Type.STRING),
            new SortField("year", SortField.Type.INT));%>
<%
// params for this page
String q = tools.getString("q", null);

// global variables
Corpus corpus = (Corpus) session.getAttribute(corpusKey);
Set<String> bookids = null;
if (corpus != null)
    bookids = corpus.books();
FieldFacet facet = alix.fieldFacet(Alix.BOOKID, TEXT);

FieldInt years = alix.fieldInt(YEAR, null); // to get min() max() year
String[] qterms = alix.tokenize(q, TEXT);
final boolean score = (qterms != null && qterms.length > 0);

OptionFacetSort fallback = OptionFacetSort.alpha;
if (score)
    fallback = OptionFacetSort.score;
OptionFacetSort sort = (OptionFacetSort) tools.getEnum("ord", fallback, Cookies.corpusSort);

BitSet bits = bits(alix, corpus, q);
// out.println()
FormEnum dic = facet.results(qterms, bits, OptionDistrib.g.scorer()); // .topTerms(bits, qTerms, null);
boolean author = (alix.info("author") != null);
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Corpus [Alix]</title>
<link href="../static/vendor/sortable.css" rel="stylesheet" />
<link href="../static/obvie.css" rel="stylesheet" />
<script src="../static/js/common.js">//</script>
<script type="text/javascript">
//give code of texts base to further Javascript
const base = "<%=base%>"; 
</script>
<script src="../static/js/corpus.js">
    //
</script>
</head>
<body class="corpus">
    <main>
        <details id="filter">
            <summary>Filtres</summary>
            <%
            if (author) {
            %>
            <label for="author">Auteur</label>
            <input id="author" name="author" autocomplete="off"
                list="author-data" size="50" type="text"
                onclick="select()" placeholder="Nom, Prénom" />
            <%
            }
            %>
            <br />
            <label for="start">Dates</label>
            <input id="start" name="start" type="number"
                min="<%=years.min()%>" max="<%=years.max()%>"
                placeholder="Début" class="year" />
            <input id="end" name="end" type="number"
                min="<%=years.min()%>" max="<%=years.max()%>"
                placeholder="Fin" class="year" />
            <br />
            <label for="title">Titre</label>
            <input id="title" name="title" autocomplete="off"
                list="title-data" type="text" size="50"
                onclick="select()" placeholder="Chercher un titre" />
        </details>
        <form method="post" id="corpus" target="_top" action=".?view=corpus">
            <table class="sortable" id="bib">
                <caption>
                    <%
if (score) {
    out.println(dic.occsFreq() + " occurrences trouvées dans " + dic.docsHit() + " chapitres");
}
else {
    out.println(((bits != null) ? bits.cardinality() : facet.docsAll()) + " chapitres");
}
                    %>
                    <input type="hidden" name="q"
                        value="<%=JspTools.escape(q)%>" />
                    <button style="float: right;" name="save"
                        type="submit">Enregistrer</button>
                    <input style="float: right;" type="text" size="10"
                        id="name" name="name"
                        value="<%=(corpus != null) ? JspTools.escape(corpus.name()) : ""%>"
                        title="Donner un nom à cette sélection"
                        placeholder="Nom ?"
                        oninvalid="this.setCustomValidity('Un nom est nécessaire pour enregistrer votre sélection.')"
                        oninput="this.setCustomValidity('')"
                        required="required" />
                </caption>
                <thead>
                    <tr>
                        <th class="checkbox"><input id="checkall"
                            type="checkbox"
                            title="Sélectionner/déselectionner les lignes visibles" /></th>
                        <th class="author">auteur</th>
                        <th class="year">date</th>
                        <th class="title">titre</th>
                        <%
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
        order = FormEnum.Order.alpha;
        break;
    case score :
        if (score)
    order = FormEnum.Order.score;
        else
    order = FormEnum.Order.alpha;
        break;
    case freq :
        if (score)
    order = FormEnum.Order.occs;
        else
    order = FormEnum.Order.alpha;
        break;
    default :
        order = FormEnum.Order.alpha;
}
dic.sort(order);

// Hack to use facet as a navigator in results
// get and cache results in facet order, find a index 
TopDocs topDocs = getTopDocs(pageContext, alix, corpus, q, OptionSort.author);
int[] nos = facet.nos(topDocs);
dic.setNos(nos);

while (dic.hasNext()) {
    dic.next();
    String bookid = dic.form();
    // String bookid = doc.get(Alix.BOOKID);
    Document doc = reader.document(alix.getDocId(bookid), FIELDS);
    // for results, do not diplay not relevant results
    /*
    if (score && dic.occs() == 0)
        continue;
    */

    out.println("<tr>");
    out.println("  <td class=\"checkbox\">");
    out.print("    <input type=\"checkbox\" name=\"book\" id=\"" + bookid + "\" value=\"" + bookid + "\"");
    if (bookids != null && bookids.contains(bookid))
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
    out.println("  <td class=\"year\">" + doc.get("year") + "</td>");
    out.println("  <td class=\"title\">");
    int n = dic.no();
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
    if (score) {
        out.println("  <td class=\"occs num\">" + dic.freq() + "</td>");
        out.println("  <td class=\"docs num\">" + dic.hits() + "</td>");
               out.println("  <td class=\"score num\">" + dfScoreFr.format(dic.score()) + "</td>");
    }
    else {
        out.println("  <td class=\"length num\">" + dfint.format(dic.occs()) + "</td>");
        out.println("  <td class=\"docs num\">" + dic.docs() + "</td>");
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

    <script src="../static/vendor/sortable.js">
                    //
                </script>
    <%
    // Loop on metadata fields to provide lists for suggestion
    for (String field : new String[]{"author", "title"}) {
        if (alix.info(field) == null)
            continue;
        facet = alix.fieldFacet(field, TEXT);
        dic = facet.results();
        out.println("<datalist id=\"" + field + "-data\">");
        dic.sort(FormEnum.Order.alpha);
        while (dic.hasNext()) {
            dic.next();
            // long weight = facetEnum.weight();
            out.println("  <option value=\"" + JspTools.escape(dic.form()) + "\"/>");
        }
        out.println("</datalist>");
    }
    %>
    <a href="#" id="gotop">▲</a>
    <script>
                    bottomLoad();
                <%if (corpus != null)
    out.println("showSelected();");%>
                    
                </script>
</body>
</html>
