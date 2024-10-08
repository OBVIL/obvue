<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="prelude.jsp"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.FieldFacet"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.FieldInt"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.TermList"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.FormEnum"%>
<%@ page import="org.apache.lucene.index.FieldInfos"%>
<%@ page import="org.apache.lucene.index.FieldInfo"%>
<%!final String fieldName = TEXT;
final static HashSet<String> FIELDS = new HashSet<String>(
    Arrays.asList(new String[]{Names.ALIX_ID, "byline", "year", "title"})
);
static Sort SORT = new Sort(new SortField("author1", SortField.Type.STRING),
            new SortField("year", SortField.Type.INT));%>
<%
// params for this page
String q = tools.getString("q", null);
Query query = alix.query(fieldName, q);
if (query == null) {
    query =  new TermQuery(new Term(Names.ALIX_TYPE, Names.ARTICLE));
}

// global variables
// Corpus corpus = (Corpus) session.getAttribute(corpusKey);
// get stats for the text field, useful to 
FieldText ftext = alix.fieldText(fieldName);

FieldInt years = null;
try {
    years = alix.fieldInt(YEAR); // to get min() max() year
}
catch (Exception e) {
}
String[] forms = alix.tokenize(q, fieldName);
final boolean hasSearch = (forms != null && fieldName.length() > 0);

// get an order for terms
OptionFacetSort fallback = OptionFacetSort.alpha;
if (hasSearch) {
    fallback = OptionFacetSort.score;
}
/*logic to choose a sort order
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
*/
OptionSort sort = (OptionSort) tools.getEnum("sort", OptionSort.score, "alixSort");
TopDocs topDocs = sort.top(searcher, query);
ScoreDoc[] hits = topDocs.scoreDocs;
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
    </head>
    <body class="corpus">
        <main>
            <table class="sortable" id="bib">
                <caption>
                    <div class="flex">
                        <div style="float: left">
<%
if (hasSearch) {
    // out.println(results.freqAll() + " occurrences trouvées dans " + results.hitsAll() + " textes");
}
else { // 
    
}
%>
                            </div>
                            <div style="text-align:right">

                            </div>
                        </div>
                    </caption>
                <thead>
                    <tr>
                        <th class="author">auteur</th>
                        <th class="title">titre</th>
                        <%
if (years != null) {
    out.println("<th class=\"year\">date</th>");
}
if (hasSearch) {
    out.println("<th class=\"occs\" title=\"Occurrences\">Occurrences</th>");
    out.println("<th class=\"length\" title=\"Taille en mots\">/ Taille</th>");
    out.println("<th class=\"score\">Score</th>");
}
                        %>
                        
                    </tr>
                </thead>
                <tbody>
<%
int n = 1;
StoredFields storedFields = reader.storedFields();
for (ScoreDoc hit : hits) {
    final int docId = hit.doc;
    // String bookid = doc.get(Alix.BOOKID);
    Document doc = storedFields.document(docId, FIELDS);
    // for results, do not diplay not relevant results
    // if (score && results.occs() == 0) continue;

    out.println("<tr>");
    // checkbox
    /*
    out.println("  <td class=\"checkbox\">");
    out.print("    <input type=\"checkbox\" name=\"book\" id=\"" + bookid + "\" value=\"" + bookid + "\"");
    if (bookids != null && bookids.contains(bookid))
        out.print(" checked=\"checked\"");
    if (score)
        out.print(" checked=\"checked\"");
    out.println(" />");
    out.println("  </td>");
    */
    // author
    out.print("  <td class=\"author\">");
    String byline = doc.get("byline");
    if (byline != null) out.print(byline);
    out.println("</td>");
    out.println("  <td class=\"title\">");
    String href;
    // hpp?
    if (hasSearch)
        href = "kwic?sort=author&amp;q=" + JspTools.escUrl(q) + "&amp;start=" + (n + 1);
    else
        href = "doc?id=" + doc.get(Names.ALIX_ID);
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
    if (hasSearch) {
        final String freq = dfint.format(Doc.freq(reader, docId, fieldName, forms));
        out.println(String.format("  <td class=\"occs num\">%s</td>", freq));
        final String occs = dfint.format(ftext.occs(docId));
        out.println(String.format("  <td class=\"occs num\">%s</td>", occs));
        String score = "";
        if (!Float.isNaN(hit.score)) {
            score = dfScoreFr.format(hit.score);
        }
        out.println(String.format("  <td class=\"score num\">%s</td>", score));
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
    /*
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
    */
    %>
        <a href="#" id="gotop">▲</a>
        <script>
// bottomLoad();
                    
        </script>
    </body>
</html>
