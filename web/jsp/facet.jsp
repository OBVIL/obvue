<%@ page language="java" pageEncoding="UTF-8"
    contentType="text/html; charset=UTF-8"
    trimDirectiveWhitespaces="true"%>
<%@include file="prelude.jsp"%>

<%
// Params for the page
String q = tools.getString("q", null);
OptionFacetSort sort = (OptionFacetSort) tools.getEnum("ord", OptionFacetSort.alpha, Cookies.facetSort);

//global variables
OptionFacet field = OptionFacet.author;
Corpus corpus = (Corpus) session.getAttribute(corpusKey);
BitSet bits = bits(alix, corpus, q);
final boolean filtered = (bits != null);
// is there a query and scores to get ?
String[] forms = alix.tokenize(q, TEXT);
final boolean queried = (forms != null && forms.length > 0);
if (!queried && sort == OptionFacetSort.score) {
    sort = OptionFacetSort.freq;
}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" />
<title>Facettes</title>
<link rel="stylesheet" type="text/css" href="../static/obvie.css" />
<script src="../static/js/common.js">
    //
</script>
<base target="page" href="snip" />
</head>
<body class="facet">
    <%
    if (alix.info(field.name()) == null) {
        out.println("<p>Cette base de textes ne comporte pas d’auteurs.</p>");
    } else {
    %>
    <form id="qform" target="_self">
        <input type="submit"
            style="position: absolute; left: -9999px; width: 1px; height: 1px;"
            tabindex="-1" /> <input type="hidden" id="q" name="q"
            value="<%=JspTools.escape(q)%>" autocomplete="off" /> <select
            name="ord" onchange="this.form.submit()">
            <option />
            <%=sort.options()%>
        </select>
    </form>
    <main>
        <%
FieldFacet facet = alix.fieldFacet(field.name(), TEXT);
FormEnum dic = facet.results(forms, bits, OptionDistrib.g.scorer());
//Hack to use facet as a navigator in results, cache results in the facet order
TopDocs topDocs = getTopDocs(pageContext, alix, corpus, q, OptionSort.author);
int[] nos = facet.nos(topDocs);
out.println("<h4>");
out.print(field.label);
out.print(" <span class=\"stats\">(");
if (queried) out.print("occurrences — ");
if (queried) out.print("chapitres trouvés / total chapitres");
else if (filtered) out.print("chapitres sélectionnés / total chapitres");
else out.print("total chapitres");
out.print(")</span>");
out.println("</h4>");

FormEnum.Order order;
switch (sort) {
    case alpha :
    	order = FormEnum.Order.alpha;
        break;
    case freq :
        if (queried) order = FormEnum.Order.freq;
        else if (filtered) order = FormEnum.Order.hits;
        else order = FormEnum.Order.occs;
        break;
    case score :
        if (queried) order = FormEnum.Order.score;
        else if (filtered) order = FormEnum.Order.hits;
        else order = FormEnum.Order.occs;
        break;
    default :
    	order = FormEnum.Order.alpha;
}
dic.sort(order);


int hits = 0, docs = 0, start = 1;
long occs = 0;

final StringBuilder href = new StringBuilder();
href.append("?sort=author");
if (q != null)
    href.append("&amp;q=").append(JspTools.escUrl(q));;
final int hrefLen = href.length();

while (dic.hasNext()) {
    dic.next();
    docs = dic.docs();
    if (filtered) {
        hits = dic.hits();
        if (hits < 1) continue; // in alpha order, try next
    }
    if (queried) {
        occs = dic.occs();
        if (hits < 1) continue; // in alpha order, try next
    }
    href.setLength(hrefLen);
    href.append("&amp;start=" + start); // parenthesis for addition!
    href.append("&amp;hpp=");
    if (filtered || queried) {
        href.append(hits);
        start = start + hits;
    }
    else {
        href.append(docs);
        start = start + docs;
    }

    out.print("<div class=\"term\">");
    out.print("<a href=\"" + href + "\">");
    out.print(dic.form());
    out.print(" <span class=\"stats\">(");
    if (queried)
        out.print(dic.freq() + " o. — ");
    if (filtered || queried)
        out.print(hits + " ch. / " + docs);
    else
        out.print(docs);
    out.print(")</span>");
    out.println("</div>");
}
        }
    out.print("</a>");
        %>
    </main>
    <script src="../static/js/facet.js">
                    //
                </script>
    <%
    out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->");
    %>
</body>
</html>
