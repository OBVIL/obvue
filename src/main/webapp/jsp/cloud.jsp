<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp"%>
<%!private String options(int[] values, int value) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0, lim = values.length; i < lim; i++) {
        sb.append("<option");
        if (value == values[i])
            sb.append(" selected=\"selected\"");
        sb.append(">");
        sb.append(values[i]);
        sb.append("</option>\n");
    }
    return sb.toString();
}%>
<%
final String q = tools.getString("q", null);
OptionCat cat = (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP, Cookies.cat);
final int count = tools.getInt("count", 0, 1000, 500, Cookies.count.name());
Corpus corpus = (Corpus) session.getAttribute(corpusKey);
int left = tools.getInt("left", 0, 10, 5, Cookies.coocLeft.name());
int right = tools.getInt("right", 0, 10, 5, Cookies.coocRight.name());
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Nuage de mots</title>
        <link rel="stylesheet" type="text/css" href="../static/obvie.css" />
        <script src="../static/js/common.js">
            //
        </script>
        <script>
            var count =
        <%=count%>
            ;
        </script>
    </head>
<body class="cloud">
    <form id="filter">
        <%
        if (corpus != null) {
            out.println("<i>" + corpus.name() + "</i>");
        }

        if (q == null) {
            // out.println(max+" termes");
        } else {
            out.println("&lt;<input style=\"width: 2em;\" name=\"left\" value=\"" + left
            + "\" title=\"Nombre de mots à gauche du pivot repris dans la liste de fréquence\"/>");
            out.print(q);
            out.println("<input style=\"width: 2em;\" name=\"right\" value=\"" + right
            + "\" title=\"Nombre de mots à droite du pivot repris dans la liste de fréquence\"/>&gt;");
        }
        %>

        <select name="count" onchange="this.form.submit()">
            <option />
            <%=options(new int[]{30, 50, 100, 200, 500, 1000}, count)%>
        </select> 
        <select name="cat" onchange="this.form.submit()">
            <option />
            <%=cat.options("NOSTOP, SUB, NAME, VERB, ADJ, ADV, ALL")%>
        </select> <input type="hidden" name="q" value="<%=JspTools.escUrl(q)%>" />
        <button type="submit">▼</button>
    </form>
    <div id="wordcloud2"></div>
    <script src="../static/vendor/wordcloud2.js">
                    //
                </script>
    <script src="../static/js/cloud.js">
                    //
                </script>
</body>
</html>
