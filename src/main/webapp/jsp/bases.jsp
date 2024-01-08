<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Properties" %>
<%@ page import="fr.sorbonne_universite.obtic.obvie.Rooter" %>
<%@ page import="com.github.oeuvres.alix.lucene.Alix" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="fr">
  <head>
    <meta charset="UTF-8">
    <title>Obvie, bases à chercher</title>
    <link href="static/obvie.css" rel="stylesheet"/>
  </head>
  <body>
    <article class="chapter">
    <div class="landing">
      <h1>Obvie</h1>
      <h3><p>OBVIE est un moteur de recherche offrant des fonctionnalités avancées de fouille (avec lemmatisation), de statistiques lexicales et de comparaison de textes.</p>
      <p>Les corpus disponibles:</p></h3>
      <ul>
      <%
      for (Map.Entry<String, Alix> entry : Alix.pool.entrySet()) {
          String corpusId = entry.getKey();
          out.println("<li>");
          out.print("<a href=\"" + corpusId + "\">");
          out.print(entry.getValue().props.get("label"));
          out.println("</a>");
          out.println("</li>");
       }
      %>
      </ul>
      <p>Pour indexer votre propre corpus, merci d'écrire un message à motasem.alrahabi@gmail.com</p>
      
      <p>Projet réalisé sous la direction de Didier Alexandre 2018-2020 <br/>
Idée et conception: Motasem Alrahabi<br/>
Contributeurs: Glenn Roe, Marine Riguet, Frédéric Glorieux<br/>
Développement: Frédéric Glorieux</p>

<p>Présentation:
<a href="https://docs.google.com/presentation/d/1jrqjm-XuSFpCiIelS30eXD3Utrk15R9eIW9NbsnZ1go/edit#slide=id.g6e92d9f579_0_41" target="_blank">
lien</a></p>

<p>Prise en main rapide:
<a href="https://docs.google.com/document/d/19h8oWHOMlJyMDIhRqxc0odLAjo-M9GoxDnWe3wwUFHM" target="_blank">
lien</a></p>

<p>Guide détaillé:
<a href="https://obvil.huma-num.fr/obvie/static/aide.html" target="_blank">
lien</a></p>
	</div>
    </article>
  </body>
</html>

