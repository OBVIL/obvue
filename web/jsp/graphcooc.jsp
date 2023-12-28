<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.util.Iterator" %>
<%@ page import="com.github.oeuvres.alix.util.EdgeSquare" %>
<%@ page import="com.github.oeuvres.alix.util.Edge" %>


<%!

private double count(FormEnum results, int formId, OptionOrder order)
{
    switch (order) {
        case score:
            return results.score(formId);
        case hits:
            return results.hits(formId);
        case freq:
            return results.freq(formId);
        default:
            return results.occs(formId);
    }

}

/**
 * Something to loop around colums of data with holes
 */
private int next(final Object[] data, final int col)
{
    final int len = data.length;
    if (len == 1) {
        // no more results, end
        if (data[0] == null) return -1;
        return 0;
    }
    int index = col;
    int done = len;
    do {
        index++;
        if (index >= len) {
            index = 0;
        }
        if (data[index] != null) {
            return index;
        }
        // no more col to test
        if (--done <= 0) {
            return -1;
        }
    }
    while (true);
}

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
String q = request.getParameter(Q);
int nodeLen = tools.getInt("nodes", 40); // count of nodes
int edgeLen = tools.getInt("edges", (int)(nodeLen * 1.8)); // count of edges
final int right = tools.getInt("right", 10);
final int left = tools.getInt("left", 10);
TagFilter tags = OptionCat.NOSTOP.tags(); // non stop words
OptionOrder order = OptionOrder.score; // default selection by score
//-----------
// check parameters
if (q == null) {
    out.println("{\"errors\":" + Error.Q_NONE.json(Q) + "}");
    return;
}
String field = TEXT; // ? lemmas or not ?
//for each requested forms, get co-occurences stats
String[] forms = alix.tokenize(q, field);
if (forms == null || forms.length < 1) {
    out.println("{\"errors\":" + Error.Q_NOTFOUND.json(Q, q) + "}");
    return;
}
final FieldText ftext = alix.fieldText(field);
final FieldRail frail = alix.fieldRail(field);
// build filter from form
Query qFilter = query(alix, tools, GRAPH_PARS);
BitSet filter = filter(alix, qFilter);
int[] pivotIds = ftext.formIds(forms, filter);
if (pivotIds == null) {
    out.println("{\"errors\":" +Error.Q_NOTFOUND.json(Q, q) + "}");
    return;
}
StringBuilder pivots = new StringBuilder();
boolean first=true;
for (int formId: pivotIds) {
    if (first) {first = false;}
    else {pivots.append(", ");}
    pivots.append(ftext.form(formId));
}
//-----------


int pivotLen = pivotIds.length;
//normalize forms
for (int i =0; i < pivotLen; i++) {
  forms[i] = ftext.form(pivotIds[i]);
}

/*
 * Idea of algo, collect list of coocs for each pivot
 */
// for each pivot word, we need a separate word list, with separate scoring
FormEnum[] stats = new FormEnum[pivotLen];
for (int i = 0; i < pivotLen; i++) {
    int[] pivotx = new int[]{pivotIds[i]};
    // build a freq list for coocs
    FormEnum results = new FormEnum(ftext);
    results.limit = nodeLen;
    results.filter = filter; // corpus filter
    results.left = left; // left context
    results.right = right; // right context
    results.tags = tags; // filter word list by tags
    // DO NOT record edges here
    long found = frail.coocs(pivotx, results); // populate the wordlist
    // sort coocs by score 
    frail.score(pivotx, results);
    results.sort(order.order());
    stats[i] = results;
}


// start data output
out.println("{ \"data\": {");

// A quite complex logic to get quite the same number of nodes for each pivot
Map<Integer, Double> nodes = new HashMap<Integer, Double>();
double nodeMin = Double.MAX_VALUE;
double nodeMax = Double.MIN_VALUE;
int nodeCount = 0;
int col = 0; // index in table list
while (nodeCount < nodeLen) {
    FormEnum results = stats[col];
    if (results == null) {
        // has been deleted should not arrived
        if ((col=next(stats, col)) < 0) break;
    }
    // no more form in this freqList, try next
    if (!results.hasNext()) {
        stats[col] = null;
        if ((col=next(stats, col)) < 0) break;
        continue;
    }
    results.next();
    final int formId = results.formId();
    double count = count(results, formId, order);
    // this list is finished, go next
    if (count <= 0) {
        stats[col] = null;
        if ((col=next(stats, col)) < 0) break;
        continue;
    }
    final int pivotId = pivotIds[col];
    boolean isPivot = false;
    // a pivot ?
    if (Arrays.binarySearch(pivotIds, formId) >= 0) {
        isPivot = true;
        nodes.put(formId, Double.MIN_VALUE);
        continue;
    }
    // min-max size of nodes keps
    // out.println(nodeCount+". "+ftext.form(pivotId)+"--"+ftext.form(formId)+" (" + count + ")");
    // node already recorded update its score 
    if (nodes.containsKey(formId)) {
        Double score = nodes.get(formId);
        // cooc shared
        score += count;
        if (score < nodeMin) {
    nodeMin = score;
        }
        if (score > nodeMax) {
    nodeMax = score;
        }
        nodes.put(formId, score);
        continue;
    }
    // new node
    nodeCount++;
    // try next col
    if ((col=next(stats, col)) < 0) break;
    if (count < nodeMin) {
        nodeMin = count;
    }
    if (count > nodeMax) {
        nodeMax = count;
    }
    // not a pivot record score
    nodes.put(formId, count);
}

// show nodes
int[] nodeIds = new int[nodes.size()];
int nodeIndex = 0;
out.println("  \"nodes\": [");
first = true;
int hub = 0;
for (Map.Entry<Integer, Double> entry : nodes.entrySet()) {
    // if (entry.getValue() < 1) continue;
    int formId = entry.getKey();
    nodeIds[nodeIndex] = formId;
    nodeIndex++;
    if (first) first = false;
    else out.println(", ");
    int tag = ftext.tag(formId);
    // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
    double size = entry.getValue();
    // pivot medium size
    if (size == Double.MIN_VALUE) {
        size = nodeMin + (nodeMax - nodeMin) / 2;
    }
    out.print("    {\"id\":\"n" + formId + "\", \"label\":" + JSONWriter.valueToString(ftext.form(formId)) + ", \"size\":" + size); // node.count
    
    out.print(", \"color\":\"" + color(tag) + "\"");
    // is a pivot
    if (entry.getValue() < 1) {
        out.print(", \"type\":\"hub\"");
        if (pivotLen == 1) {
    out.print(", \"x\":" + 50 + ", \"y\":" + 50 );
        }
        else if (hub < 8) {
    final int[] xx = new int[]{0, 100, 50, 50, 0, 100, 100, 0};
    final int[] yy = new int[]{50, 50, 0,  100, 0, 100, 0, 100};
    out.print(", \"x\":" + xx[hub] + ", \"y\":" + yy[hub] );
        }
        else {
    out.print(", \"x\":" + ((int)(Math.random() * 100)) + ", \"y\":" + ((int)(Math.random() * 100)) );
        }
        hub++;
    }
    else {
        out.print(", \"x\":" + ((int)(Math.random() * 100)) + ", \"y\":" + ((int)(Math.random() * 100)) );
    }
    out.print("}");
}
out.println("\n  ],");
out.flush();
// build edges
EdgeSquare edges = frail.edges(pivotIds, left, right, nodeIds, filter);
out.println("  \"edges\": [");
first = true;
int edgeCount = 0;


for (Edge edge: edges) {
    if (edge == null) { // bug
        break;
    }
    if (edge.source == edge.target) {
        continue;
    }
    double score = 0.1;
    if (score > 0) score = edge.score();
    if (first) first = false;
    else out.println(", ");
    out.print("    {\"id\":\"e" + (edgeCount) + "\", \"source\":\"n" + edge.source + "\", \"target\":\"n" + edge.target + "\", \"size\":" + score 
    // + ", color:'rgba(192, 192, 192, 0.2)'"
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
    out.print(", \"pivots\": " + JSONWriter.valueToString(pivots));
    out.print("}");
    out.println("}");
}
out.flush();
%>



