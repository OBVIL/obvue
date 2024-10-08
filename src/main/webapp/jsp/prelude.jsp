<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="java.io.FileInputStream"%>
<%@ page import="java.io.IOException"%>
<%@ page import="java.nio.file.Path"%>
<%@ page import="java.nio.file.Paths"%>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="java.util.*"%>
<%@ page import="org.apache.lucene.analysis.Analyzer"%>
<%@ page import="org.apache.lucene.document.Document"%>
<%@ page import="org.apache.lucene.index.IndexReader"%>
<%@ page import="org.apache.lucene.index.StoredFields"%>
<%@ page import="org.apache.lucene.index.Term"%>
<%@ page import="org.apache.lucene.search.*"%>
<%@ page import="org.apache.lucene.search.BooleanClause.Occur"%>
<%@ page import="org.apache.lucene.util.BitSet"%>
<%@ page import="com.github.oeuvres.alix.Names"%>
<%@ page import="com.github.oeuvres.alix.lucene.Alix"%>
<%@ page import="com.github.oeuvres.alix.lucene.Alix.FSDirectoryType"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.AlixAnalyzer"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.*"%>
<%@ page import="com.github.oeuvres.alix.util.ML"%>
<%@ page import="com.github.oeuvres.alix.web.*"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.GallicaIndexer"%>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter"%>
<%!/** Field name containing canonized text */
public static String TEXT = "text";
/** Field Name with int date */
final static String YEAR = "year";
/** Key prefix for current corpus in session */
public static String CORPUS_ = "corpus_";
/** A filter for documents */
final static Query QUERY_ARTICLE = new TermQuery(new Term(Names.ALIX_TYPE, Names.ARTICLE));

final static DecimalFormatSymbols frsyms = DecimalFormatSymbols.getInstance(Locale.FRANCE);
final static DecimalFormat dfScoreFr = new DecimalFormat("0.00000", frsyms);
final static DecimalFormat dfint = new DecimalFormat("###,###,##0", frsyms);
final static DecimalFormatSymbols ensyms = DecimalFormatSymbols.getInstance(Locale.ENGLISH);
static final DecimalFormat dfdec3 = new DecimalFormat("0.###", ensyms);

/**
 * Control proliferation of cookies. All of them are user interface customization, 
 * without personal information. Do not require consent.
 */
public enum Cookies
{
    count, coocLeft, coocRight, corpusSort, docSort, expression, facetSort, freqsSort, cat, distrib, mi;
}

/** 
 * All pars for all page 
 */
public class Pars
{
    String book; // restrict to a book
    String q; // word query
    OptionCat cat; // word categories to filter
    OptionOrder order;// order in list of terms and facets
    int limit; // results, limit of result to show
    int nodes; // number of nodes in wordnet
    int context; // coocs, context width in words
    int left; // coocs, left context in words
    int right; // coocs, right context in words
    boolean expression; // kwic, filter multi word expression
    OptionMime mime; // mime type for output

    // too much scoring algo
    OptionDistrib distrib; // ranking algorithm, tf-idf like
    OptionMI mi; // proba kind of scoring, not tf-idf, [2, 2]

    int start; // start record in search results
    int hpp; // hits per page
    String href;
    String[] forms;
    OptionSort sort;
}

public Pars pars(final PageContext page)
{
    Pars pars = new Pars();
    JspTools tools = new JspTools(page);

    // pars.field = (Field) tools.getEnum("f", Field.text, "alixField");
    pars.q = tools.getString("q", null);
    pars.book = tools.getString("book", null); // limit to a book
    // Words
    pars.cat = (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP); // 

    // ranking, sort… a bit a mess
    pars.distrib = (OptionDistrib) tools.getEnum("distrib", OptionDistrib.BM25);
    pars.mi = (OptionMI) tools.getEnum("mi", OptionMI.G);
    // default sort in documents
    pars.sort = (OptionSort) tools.getEnum("sort", OptionSort.score, "alixSort");
    //final FacetSort sort = (FacetSort)tools.getEnum("sort", FacetSort.freq, Cookies.freqsSort);
    pars.order = (OptionOrder) tools.getEnum("order", OptionOrder.SCORE, "alixOrder");

    String format = tools.getString("format", null);
    //if (format == null) format = (String)request.getAttribute(Dispatch.EXT);
    pars.mime = (OptionMime) tools.getEnum("format", OptionMime.html);

    pars.limit = 100;
    pars.limit = tools.getInt("limit", pars.limit);
    // user should know his limits

    final int nodesMax = 300;
    final int nodesMid = 50;
    pars.nodes = tools.getInt("nodes", nodesMid);
    if (pars.nodes < 1)
        pars.nodes = nodesMid;
    if (pars.nodes > nodesMax)
        pars.nodes = nodesMax;

    // coocs
    pars.left = tools.getInt("left", 0);
    pars.right = tools.getInt("right", 0);
    if (pars.left < 0)
        pars.left = 0;
    if (pars.right < 0)
        pars.right = 0;
    if (pars.left + pars.right == 0) {
        pars.left = 5;
        pars.right = 5;
    }
    /*
    else if (pars.left > 10) pars.left = 50;
    pars.right = tools.getInt("right", 5);
    else if (pars.right > 10) pars.right = 50;
    */

    // paging
    final int hppDefault = 100;
    final int hppMax = 1000;
    pars.expression = tools.getBoolean("expression", false);
    pars.hpp = tools.getInt("hpp", hppDefault);
    if (pars.hpp > hppMax || pars.hpp < 1)
        pars.hpp = hppDefault;
    pars.sort = (OptionSort) tools.getEnum("sort", OptionSort.year);
    pars.start = tools.getInt("start", 1);
    if (pars.start < 1)
        pars.start = 1;

    return pars;
}

/**
 * Sorting facets
 */
public enum OptionFacetSort implements Option {
    /** Ordre alphabétique */
    alpha("Alphabétique"), 
    /** Fréquence */
    freq("Fréquence"), 
    /** Algorithme de pertinence */
    score("Pertinence"),
    ;
    // sadly repeating myself because enum can’t inherit from an abstract class (an Enum already extends a class). 
    public final String label;
    final public String hint = "";
    private OptionFacetSort(final String label) {  
        this.label = label ;
    }
    public String label() { return label; }
    @Override
    public String hint() { return hint; }
}

public enum OptionFacet implements Option {
    author("Auteur"), 
    ;
    public final String label;
    final public String hint = "";
    private OptionFacet(final String label) {    
        this.label = label ;
    }
    public String label() { return label; }
    public String hint() { return hint; }
}

/**
 * Build a filtering query with a corpus
 */
public static Query corpusQuery(Corpus corpus, Query query) throws IOException {
    if (corpus == null)
        return query;
    BitSet filter = corpus.bits();
    if (filter == null)
        return query;
    if (query == null)
        return new CorpusQuery(corpus.name(), filter);
    return new BooleanQuery.Builder().add(new CorpusQuery(corpus.name(), filter), Occur.FILTER)
            .add(query, Occur.MUST).build();
}

/**
 * Build a text query fron a String and an optional Corpus.
 * Will return null if there is no terms in the query,
 * even if there is a corpus.
 */
public static Query getQuery(Alix alix, String q, Corpus corpus) throws IOException {
    String fieldName = TEXT;
    Query qWords = alix.query(fieldName, q);
    if (qWords == null) {
        return null;
        // return filter;
    }
    if (corpus != null) {
        Query filter = new CorpusQuery(corpus.name(), corpus.bits());
        return new BooleanQuery.Builder().add(filter, Occur.FILTER).add(qWords, Occur.MUST).build();
    }
    return qWords;
}

/**
 * Get a bitSet of a query. Seems quite fast (2ms), no cache needed.
 */
public BitSet bits(Alix alix, Corpus corpus, String q) throws IOException {
    Query query = getQuery(alix, q, corpus);
    if (query == null && corpus == null) {
        return null;
    }
    if (query == null && corpus != null) {
        return corpus.bits();
    }
    IndexSearcher searcher = alix.searcher();
    CollectorBits collector = new CollectorBits(searcher);
    searcher.search(query, collector);
    return collector.bits();
}

/**
 * Get a cached set of results.
 * Ensure to always give something.
 * Seems quite fast (2ms), no cache needed.
 * Cache bug if corpus is changed under same name.
 */
public TopDocs getTopDocs(PageContext page, Alix alix, Corpus corpus, String q, OptionSort sorter)
        throws IOException {
    // build the key 
    Query query = getQuery(alix, q, corpus);
    if (query != null)
        ; // get a query, nothing to do
    else if (corpus != null)
        query = new CorpusQuery(corpus.name(), corpus.bits());
    else
        query = QUERY_ARTICLE;
    Sort sort = sorter.sort;
    String key = "" + page.getRequest().getAttribute(Rooter.BASE) + "?" + query;
    if (sort != null)
        key += " " + sort;
    /*
    Similarity oldSim = null;
    Similarity similarity = getSimilarity(sortSpec);
    if (similarity != null) {
      key += " <"+similarity+">";
    }
    */
    TopDocs topDocs = null;

    // topDocs = (TopDocs)page.getSession().getAttribute(key);

    IndexSearcher searcher = alix.searcher();
    int totalHitsThreshold = Integer.MAX_VALUE;
    final int numHits = alix.reader().maxDoc();
    // TODO allDocs collector
    TopDocsCollector<?> collector;
    SortField sf2 = new SortField(Names.ALIX_ID, SortField.Type.STRING);
    Sort sort2 = new Sort(sf2);
    if (sort != null) {
        collector = TopFieldCollector.create(sort, numHits, totalHitsThreshold);
    } else {
        collector = TopScoreDocCollector.create(numHits, totalHitsThreshold);
    }
    /*
    if (similarity != null) {
      oldSim = searcher.getSimilarity();
      searcher.setSimilarity(similarity);
      searcher.search(query, collector);
      // will it be fast enough to not affect other results ?
      searcher.setSimilarity(oldSim);
    }
    else {
    }
    */
    searcher.search(query, collector);
    topDocs = collector.topDocs();
    // page.getSession().setAttribute(key, topDocs);
    return topDocs;
}%>
<%
final long time = System.nanoTime();
final ServletContext servletContext = pageContext.getServletContext();
final File dataDir = (File)servletContext.getAttribute(Rooter.DATADIR);
final String base = (String)request.getAttribute(Rooter.BASE);
final File baseDir = new File(dataDir, base);

Path lucenePath = Paths.get(dataDir.getCanonicalPath(), base, GallicaIndexer.LUCENE);


final JspTools tools = new JspTools(pageContext);
// load and cache a lucene Reader
final Alix alix;
if (Alix.hasInstance(base)) {
    alix = Alix.instance(base);
}
else {
    alix = Alix.instance(base, lucenePath, new AlixAnalyzer(), null);
    File propsFile = new File(baseDir, GallicaIndexer.PROPS_FILE);
    if (propsFile.canRead()) {
        alix.props.loadFromXML(new FileInputStream(propsFile));
    }
}
final IndexSearcher searcher = alix.searcher();
final IndexReader reader = alix.reader();
final String corpusKey = CORPUS_ + base;
final String hrefHome = "../";
%>