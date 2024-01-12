<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.text.DecimalFormatSymbols"%>
<%@ page import="java.util.Locale"%>
<%@ page
    import="org.apache.lucene.analysis.miscellaneous.ASCIIFoldingFilter"%>
<%@ page import="com.github.oeuvres.alix.fr.Tag"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.tokenattributes.CharsAtt"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.FrDics"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.FrDics.LexEntry"%>
<%@ page import="com.github.oeuvres.alix.util.Char"%>
<%!private static final int OUT_HTML = 0;
private static final int OUT_CSV = 1;
private static final int OUT_JSON = 2;
static final DecimalFormat frdec = new DecimalFormat("###,###,###,###", frsyms);
static final DecimalFormat dfdec5 = new DecimalFormat("0.00000", ensyms);
static final DecimalFormat dfsc = new DecimalFormat("0.00000E0", frsyms);
static final DecimalFormat frdec2 = new DecimalFormat("###,###,###,##0.00", frsyms);

static String formatScore(double real) {
    if (real == 0)
        return "0";
    if (real == (int) real)
        return frdec.format(real);
    double offset = Math.log10(real);
    if (offset < -3)
        return dfsc.format(real);
    if (offset < -2)
        return dfdec5.format(real);
    if (offset > 4)
        return frdec.format((int)real);

    // return String.format("%,." + (digits - offset) + "f", real)+" "+offset;
    return frdec2.format(real);
}

private static void lines(JspWriter out, final FormEnum dic, int max, final OptionMime mime, final OptionCat cat,
        final String q, final boolean filtered) throws IOException {
    if (max <= 0)
        max = dic.limit();
    else
        max = Math.min(max, dic.limit());

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
                    out.append(",\n");
                jsonLine(out, dic, no, q, filtered);
                break;
            case csv :
                csvLine(out, dic, no, q, filtered);
                break;
            default :
                htmlLine(out, dic, no, q, filtered);
        }
        no++;
        first = false;
    }
}

/**
 * An html table row &lt;tr&gt; for lexical frequence result.
 */
private static void htmlLine(JspWriter out, final FormEnum dic, final int no, final String q, final boolean filtered) throws IOException {
    String term = dic.form();
    // .replace('_', ' ') ?
    out.append("  <tr>\n");
    out.append("    <td class=\"no\">" + no + ".</td>\n");
    out.append("    <td><a");
    if (q != null) {
        out.append(" href=\"kwic?sort=score&amp;q=");
        out.append(q);
        out.append(" %2B").append(term);
        out.append("&amp;expression=on");
        out.append("\"");
    } else {
        out.append(" href=\".?q=");
        out.append(term);
        out.append("\"");
        out.append(" target=\"_top\"");
    }
    out.append(">");
    out.append(term);
    out.append("</a></td>\n");
    // tag
    out.append("    <td>");
    final int flag = dic.tag();
    out.append(Tag.name(flag));
    out.append("</td>\n");
    
    // doc founds
    out.append("    <td class=\"num\">");
    out.append(""+dic.hits());
    out.append("</td>\n");
    
    if (q != null || filtered) {
        out.append("    <td class=\"num all\">");
        out.append("/ "+frdec.format(dic.docs()));
        out.append("</td>");
    }

    // occs found
    out.append("    <td class=\"num\">");
    out.append(frdec.format(dic.freq()));
    out.append("</td>");

    if (q != null || filtered) {
        out.append("    <td class=\"num all\">");
        out.append("/ "+frdec.format(dic.occs()));
        out.append("</td>");
    }

    // score
    out.append("    <td class=\"num\">");
    out.append(formatScore(dic.score()));
    out.append("</td>");
    
    out.append("  </tr>\n");
}

private static void csvLine(JspWriter out, final FormEnum dic, final int no, final String q, final boolean filtered) throws IOException {
    out.append(dic.form().replaceAll("\t\n", " "));
    final int flag = dic.tag();
    out.append("\t").append(Tag.name(flag));
    out.append("\t").append(""+dic.hits());
    out.append("\t");
    if (q != null) out.append(""+dic.freq());
    else if (filtered) out.append(""+dic.freq());
    else out.append(""+dic.occs());
    out.append("\n");
}

static private void jsonLine(JspWriter out, final FormEnum dic, final int no, final String q, final boolean filtered) throws IOException {
    out.append("    {\"word\" : \"");
    out.append(dic.form().replace("\"", "\\\"").replace('_', ' '));
    out.append("\"");
    out.append(", \"weight\" : ");
    if (q != null) out.append(dfdec3.format(dic.freq()));
    else if (filtered) out.append(dfdec3.format(dic.freq()));
    else out.append(dfdec3.format(dic.occs()));
    out.append(", \"attributes\" : {\"class\" : \"");
    final int flag = dic.tag();
    out.append(Tag.name(flag));
    out.append("\"}");
    out.append("}");
}%>
<%
//parameters
final String q = tools.getString("q", null);
int count = tools.getInt("count", -1);
if (count < 1 || count > 2000)
    count = 500;

final OptionFacetSort sort = (OptionFacetSort) tools.getEnum("sort", OptionFacetSort.freq, Cookies.freqsSort);
OptionCat cat = (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP, Cookies.cat);

OptionDistrib distrib = (OptionDistrib) tools.getEnum("distrib", OptionDistrib.OCCS, Cookies.distrib);
OptionMI mi = (OptionMI) tools.getEnum("mi", OptionMI.OCCS, Cookies.mi);

int left = tools.getInt("left", 0, 10, 5, Cookies.coocLeft.name());
int right = tools.getInt("right", 0, 10, 5, Cookies.coocRight.name());

// global variables
final String field = TEXT; // the field to process
BitSet filter = null; // if a corpus is selected, filter results with a bitset
Corpus corpus = (Corpus) session.getAttribute(corpusKey);
if (corpus != null) filter = corpus.bits();

FieldText ftext = alix.fieldText(field);
FormEnum dic = null; // the dictionary to extract
String[] words = alix.tokenize(q, TEXT);;
int[] pivotIds = ftext.formIds(words, filter);
if (q == null) {
    dic = ftext.forms(filter, cat.tags(), distrib);
    dic.sort(OptionOrder.SCORE.order(), count);
} 
else if (pivotIds == null) {
    // what should be done here ?
}
else {
    FieldRail rail = alix.fieldRail(field);
    dic = ftext.forms();
    dic.filter = filter; // corpus
    dic.tags = cat.tags();
    long found = rail.coocs(dic, pivotIds, left, right, mi); // populate the wordlist
    dic.sort(OptionOrder.SCORE.order(), count);
}

String format = tools.getString("format", null);
if (format == null)
    format = (String) request.getAttribute(Rooter.EXT);
OptionMime mime;
try {
    mime = OptionMime.valueOf(format);
} catch (Exception e) {
    mime = OptionMime.html;
}

if (OptionMime.json.equals(mime)) {
    response.setContentType(OptionMime.json.type);
    out.println("{");
    if (dic == null && q != null) {
        out.println("\"error\":\"Mots non trouvés:" + q + "\"");
    }
    else {
        out.println("  \"data\":[");
        lines(out, dic, count, mime, cat, q, (filter != null));
        out.println("\n  ]");
    }
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
    if (dic == null && q != null) {
        out.println("Mots non trouvés : \"" + q + "\"");
    }
    else {
        out.print("Mot\tType\tChapitres\tOccurrences");
        out.println();
        lines(out, dic, -1, mime, cat, q, (filter != null));
    }
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
    <form id="sortForm">
    <table class="sortable">
        <caption>
            <a class="csv"
            href="freqs.csv?q=<%=JspTools.escape(q)%>&amp;left=<%=left%>&amp;right=<%=right%>&amp;cat=<%=cat%>&amp;sort=<%=sort%>">csv 🡵</a>
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
        </caption>
        <thead>
            <tr>
                <th>No</th>
                <th title="Forme graphique indexée" class="form">Mot</th>
                <th title="Catégorie grammaticale">Type</th>
                
                <% 
if (q != null || filter != null) {
    out.println("<th title=\"Nombre de textes trouvés contenant le mot\" class=\"num\"> Textes</th>");
    out.println("<th title=\"Nombre total de textes contenant le mot\" class=\"all\">/textes</th>");
}
else {
    out.println("<th title=\"Nombre de textes contenant le mot\" class=\"num\"> Textes</th>");
}
                %>
                
                <% 
if (q != null || filter != null) {
    out.println("<th title=\"Nombre d’occurrences trouvées\" class=\"num\"> Occurrences</th>");
    out.println("<th title=\"Sur total des occurences de cette graphie\" class=\"all\">/occurrences</td>");
}
else {
    out.println("<th title=\"Nombre total d’occurences de ce mot\" class=\"all\">Occurrences</td>");
    
}
out.println("<th title=\"Score, avec algorithme\">");
if (q != null) {
    out.println("<select name=\"mi\" onchange=\"this.form.submit()\"><option/>");
    out.println(mi.options());
    out.println("</select>");
}
else {
    out.println("<select name=\"distrib\" onchange=\"this.form.submit()\"><option/>");
    out.println(distrib.options());
    out.println("</select>");
}
out.println("</th>");

                
                %>
            <tr>
        </thead>
        <tbody>
            <%
if (dic == null && q != null) {
    out.println("<td colspan=\"7\">Aucune occurrences trouvées pour la requête : \"" + q + "\"<td>");
}
else {
    lines(out, dic, count, mime, cat, q, (filter != null));
}
            %>
        </tbody>
    </table>
    </form>

    <%
    out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->");
// <script src="../static/vendor/sortable.js">//</script>
    %>
    </body>
<!--((System.nanoTime() - time) / 1000000.0).0) %> ms  -->
</html>
<%
}
%>
