<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp"%>
<%@ page import="alix.util.Edge" %>
<%@ page import="alix.util.EdgeSquare" %>

<%!
/**
 * Frequent words linked by co-occurrence
 */
%>
<%
//-----------
//data common prelude
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
Alix alix = alix(tools, null); 
if (alix == null) {
    return;
}
String ext = tools.getStringOf("ext", Set.of(".json", ".js"), ".json");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//-----------
// parameters
int nodeLen = tools.getInt("nodes", 50); // count of nodes
int edgeLen = tools.getInt("edges", (int)(nodeLen * 2)); // count of edges
int dist = tools.getInt("dist", 15); // distance between words, too small produce islands for smal texts
String field = tools.getString("f", TEXT);
// TagFilter tags = OptionCat.NOSTOP.tags();
TagFilter tags = OptionCat.NOSTOP.tags();
// OptionDistrib.Scorer scorer = OptionDistrib.bm25.scorer();
OptionDistrib.Scorer scorer = null;
FormEnum.Order nodesOrder = FormEnum.Order.SCORE; // sort the nodes
if (scorer == null) {
    nodesOrder = FormEnum.Order.FREQ; // global occs will not be tag filtered
}
//-----------
// check parameters
//-----------

final FieldText ftext = alix.fieldText(field);
final FieldRail frail = alix.fieldRail(field);
// define the partition filter
Query qFilter = query(alix, tools, GRAPH_PARS);
BitSet filter = filter(alix, qFilter);

//get nodes and sort them
FormEnum nodes = ftext.forms(tags, scorer, filter);
int[] formIds = nodes.sort(nodesOrder, nodeLen);
nodeLen = formIds.length; // if less than requested
//build edges from selected nodes and get the iterator to avoid orphans
EdgeSquare edges =  frail.edges(formIds, dist, filter);
EdgeSquare.EdgeIt edgeIt = (EdgeSquare.EdgeIt)edges.iterator();


// output data
out.println("{ \"data\": {");
boolean first;
out.println("  \"nodes\": [");
first = true;
nodes.reset();
int rank = 1;
while(nodes.hasNext()) {
    nodes.next();
    final int formId = nodes.formId();
    // avoid orphans, in short text, common words may have no links with others
    if (edgeIt.top(formId).count() < 1) {
        continue;
    } 
    if (first) {
    	first = false;
    }
    else {
    	out.println(", ");
    }
    int tag = ftext.tag(formId);
    double size = nodes.freq();
    
    out.print("    {");
    out.print("\"rank\":" + rank);
    out.print(", \"id\":\"n" + formId + "\", \"label\":" + JSONWriter.valueToString(ftext.form(formId)) + ", \"size\":" + size); // node.count
    out.print(", \"color\":\"" + color(tag) + "\"");
    // try a significant positionning ?
    out.print(", \"occs\":" + nodes.occs() + "");
    out.print(", \"docs\":" + nodes.docs() + "");
    out.print(", \"hits\":" + nodes.hits() + "");
    out.print(", \"freq\":" + nodes.freq() + "");
    out.print(", \"score\":" + nodes.score() + "");
    out.print(", \"x\":" + ((int)(Math.random() * 100)) + ", \"y\":" + ((int)(Math.random() * 100)) );
    out.print("}");
    rank++;
}
out.println("\n  ],");




out.println("  \"edges\": [");
first = true;
int edgeCount = 0;

while(edgeIt.hasNext()) {
    Edge edge = edgeIt.next();
    if (edge == null) break; // may arrive
    if (edge.source == edge.target) {
        continue;
    }
    double score = 0.1;
    if (edge.score() > 0) score = edge.score();
    if (first) first = false;
    else out.println(", ");
    
    out.print("    {\"id\":\"e" + (edgeCount) + "\", \"source\":\"n" + edge.source + "\", \"target\":\"n" + edge.target + "\", \"size\":" + (score) 
        + ", \"title\":" + JSONWriter.valueToString(ftext.form(edge.source)+" -- " + ftext.form(edge.target)) 
        // + ", \"color\":\"rgba(192, 192, 192, 0.2)\""
    // for debug
    // + ", srcLabel:'" + ftext.form(srcId).replace("'", "\\'") + "', srcOccs:" + ftext.formOccs(srcId) + ", dstLabel:'" + ftext.form(dstId).replace("'", "\\'") + "', dstOccs:" + ftext.formOccs(dstId) + ", freq:" + freqList.freq()
    + "}");
    if (++edgeCount >= edgeLen) {
        break;
    }
}
out.println("\n  ]");
if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("\n}, \"meta\": {");
    out.print("\"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
    out.print(", \"query\": " + JSONWriter.valueToString(qFilter));
    out.print("}");
    out.println("}");
}
%>



