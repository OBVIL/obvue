<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.text.DecimalFormatSymbols"%>
<%@ page import="java.util.Locale"%>
<%@ page
    import="org.apache.lucene.analysis.miscellaneous.ASCIIFoldingFilter"%>
<%@ page import="alix.fr.Tag"%>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsAtt"%>
<%@ page import="alix.lucene.analysis.FrDics"%>
<%@ page import="alix.lucene.analysis.FrDics.LexEntry"%>
<%@ page import="alix.util.Char"%>
<%!
private static final int OUT_HTML = 0;
private static final int OUT_CSV = 1;
private static final int OUT_JSON = 2;

private static String lines(final FormEnum dic, int max, final OptionMime mime, final OptionCat cat,
        final String q, final boolean filtered) {
    if (max <= 0)
        max = dic.limit();
    else
        max = Math.min(max, dic.limit());
    StringBuilder sb = new StringBuilder();

    int no = 1;
    int flag;
    // dictonaries coming fron analysis, wev need to test attributes
    CharsAtt term = new CharsAtt();
    boolean first = true;
    while (dic.hasNext()) {
        dic.next();
        dic.form(term);
        if (term.isEmpty())
            continue; // empty position
        if (dic.occs() == 0)
            break;
        if (no >= max)
            break;

        switch (mime) {
            case json :
                if (!first)
                    sb.append(",\n");
                jsonLine(sb, dic, no, q, filtered);
                break;
            case csv :
                csvLine(sb, dic, no, q, filtered);
                break;
            default :
                htmlLine(sb, dic, no, q, filtered);
        }
        no++;
        first = false;
    }

    return sb.toString();
}

/**
 * An html table row &lt;tr&gt; for lexical frequence result.
 */
private static void htmlLine(StringBuilder sb, final FormEnum dic, final int no, final String q, final boolean filtered) {
    String term = dic.form();
    // .replace('_', ' ') ?
    sb.append("  <tr>\n");
    sb.append("    <td class=\"no\">" + no + ".</td>\n");
    sb.append("    <td><a");
    if (q != null) {
        sb.append(" href=\"kwic?sort=score&amp;q=");
        sb.append(q);
        sb.append(" %2B").append(term);
        sb.append("&amp;expression=on");
        sb.append("\"");
    } else {
        sb.append(" href=\".?q=");
        sb.append(term);
        sb.append("\"");
        sb.append(" target=\"_top\"");
    }
    sb.append(">");
    sb.append(term);
    sb.append("</a></td>\n");
    sb.append("    <td>");
    final int flag = dic.tag();
    sb.append(Tag.label(flag));
    sb.append("</td>\n");
    sb.append("    <td class=\"num\">");
    sb.append(dic.hits());
    sb.append("</td>\n");
    sb.append("    <td class=\"num\">");
    if (q != null) sb.append(dic.freq());
    else if (filtered) sb.append(dic.freq());
    else sb.append(dic.occs());
    sb.append("</td>\n");
    sb.append("  </tr>\n");
}

private static void csvLine(StringBuilder sb, final FormEnum dic, final int no, final String q, final boolean filtered) {
    sb.append(dic.form().replaceAll("\t\n", " "));
    final int flag = dic.tag();
    sb.append("\t").append(Tag.label(flag));
    sb.append("\t").append(dic.hits());
    sb.append("\t");
    if (q != null) sb.append(dic.freq());
    else if (filtered) sb.append(dic.freq());
    else sb.append(dic.occs());
    sb.append("\n");
}

static private void jsonLine(StringBuilder sb, final FormEnum dic, final int no, final String q, final boolean filtered) {
    sb.append("    {\"word\" : \"");
    sb.append(dic.form().replace("\"", "\\\"").replace('_', ' '));
    sb.append("\"");
    sb.append(", \"weight\" : ");
    if (q != null) sb.append(dfdec3.format(dic.freq()));
    else if (filtered) sb.append(dfdec3.format(dic.freq()));
    else sb.append(dfdec3.format(dic.occs()));
    sb.append(", \"attributes\" : {\"class\" : \"");
    final int flag = dic.tag();
    sb.append(Tag.name(flag));
    sb.append("\"}");
    sb.append("}");
}
%>
<%
//parameters
final String q = tools.getString("q", null);
int count = tools.getInt("count", -1);
if (count < 1 || count > 2000)
    count = 500;

final OptionFacetSort sort = (OptionFacetSort) tools.getEnum("sort", OptionFacetSort.freq, Cookies.freqsSort);
OptionCat cat = (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP, Cookies.cat);

int left = tools.getInt("left", 5, Cookies.coocLeft);
if (left < 0)
    left = 0;
else if (left > 10)
    left = 10;
int right = tools.getInt("right", 5, Cookies.coocRight);
if (right < 0)
    right = 0;
else if (right > 10)
    right = 10;

// global variables
final String field = TEXT; // the field to process
BitSet filter = null; // if a corpus is selected, filter results with a bitset
Corpus corpus = (Corpus) session.getAttribute(corpusKey);
if (corpus != null) filter = corpus.bits();

FieldText ftext = alix.fieldText(field);
FormEnum dic; // the dictionary to extract
if (q == null) {
    dic = ftext.results(cat.tags(), null, filter);
    dic.sort(OptionOrder.freq.order(), count);
} 
else {
    FieldRail rail = alix.fieldRail(field);
    dic = new FormEnum(ftext);
    dic.filter = filter; // corpus
    dic.left = left; // left context
    dic.right = right; // right context
    dic.search = alix.tokenize(q, TEXT);
    dic.tags = cat.tags();
    long found = rail.coocs(dic); // populate the wordlist
    dic.sort(OptionOrder.freq.order(), count);
}

String format = tools.getString("format", null);
if (format == null)
    format = (String) request.getAttribute(Dispatch.EXT);
OptionMime mime;
try {
    mime = OptionMime.valueOf(format);
} catch (Exception e) {
    mime = OptionMime.html;
}

if (OptionMime.json.equals(mime)) {
    response.setContentType(OptionMime.json.type);
    out.println("{");
    out.println("  \"data\":[");
    out.println(lines(dic, count, mime, cat, q, (filter != null)));
    out.println("\n  ]");
    out.println("\n}");
}
else if (OptionMime.csv.equals(mime)) {
    response.setContentType(OptionMime.csv.type);
    StringBuffer sb = new StringBuffer().append(base);
    if (corpus != null) {
        sb.append('-').append(corpus.name());
    }

    if (q != null) {
        String zeq = q.trim().replaceAll("[ ,;]+", "-");
        int limit = Math.min(zeq.length(), 30);
        char[] zeqchars = new char[limit * 4]; // 
        ASCIIFoldingFilter.foldToASCII(zeq.toCharArray(), 0, zeqchars, 0, limit);
        sb.append('_').append(zeqchars, 0, limit);
    }
    response.setHeader("Content-Disposition", "attachment; filename=\"" + sb + ".csv\"");
    out.print("Mot\tType\tChapitres\tOccurrences");
    out.println();
    out.print(lines(dic, -1, mime, cat, q, (filter != null)));
} 
else {
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Fréquences, <%=(corpus != null) ? JspTools.escape(corpus.name()) + ", " : ""%><%=alix.props.get("label")%> [Obvie]</title>
        <script src="../static/js/common.js">//</script>
        <link href="../static/vendor/sortable.css" rel="stylesheet" />
        <link href="../static/obvie.css" rel="stylesheet" />
    </head>
    <body>
    <table class="sortable">
        <caption>
            <a class="csv"
            href="freqs.csv?q=<%=JspTools.escape(q)%>&amp;left=<%=left%>&amp;right=<%=right%>&amp;cat=<%=cat%>&amp;sort=<%=sort%>">csv 🡵</a>
            <form id="sortForm">
                <%
                if (corpus != null) {
                    out.println("<i>" + corpus.name() + "</i>");
                }

                if (q == null) {
                    // out.println(max+" termes");
                } else {
                    out.println("&lt;<input style=\"width: 2em;\" name=\"left\" value=\"" + left + "\"/>");
                    out.print(q);
                    out.println("<input style=\"width: 2em;\" name=\"right\" value=\"" + right + "\"/>&gt;");
                    out.println("<input type=\"hidden\" name=\"q\" value=\"" + JspTools.escape(q) + "\"/>");
                }
                %>
                <select name="cat" onchange="this.form.submit()">
                    <option />
                    <%=cat.options("NOSTOP, SUB, NAME, VERB, ADJ, ADV, ALL")%>
                </select>
                <button type="submit">▼</button>
            </form>
        </caption>
        <thead>
            <tr>
                <%
                out.println("<th>No</th>");
                out.println("<th>Mot</th>");
                out.println("<th>Type</th>");
                out.println("<th>Chapitres</th>");
                out.println("<th>Occurrences</th>");
                %>
            
            <tr>
        </thead>
        <tbody>
            <%=lines(dic, count, mime, cat, q, (filter != null))%>
        </tbody>
    </table>
    <%
    out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->");
    %>
    <script src="../static/vendor/sortable.js">
                    //
                </script>
    </body>
<!--((System.nanoTime() - time) / 1000000.0).0) %> ms  -->
</html>
<%
}
%>
