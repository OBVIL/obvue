<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Properties" %>
<%@ page import="obvie.Dispatch" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr" lang="fr">
  <head>
    <meta charset="UTF-8">
    <title>Obvie, bases à chercher</title>
    <link href="static/obvie.css" rel="stylesheet"/>
  </head>
  <body>
    <article class="chapter">
      <h1>Obvie</h1>
      <h3>OBVIE est un moteur de recherche offrant des fonctionnalités avancées de fouille (avec lemmatisation), de statistiques lexicales et de comparaison de textes.</h3>
      <ul>
      <%
  HashMap<String, Properties> baseList = (HashMap<String, Properties>)request.getAttribute(Dispatch.BASE_LIST);
  int size = baseList.size();
  String[] keys = new String[size];
  keys = baseList.keySet().toArray(keys);
  Arrays.sort(keys);
  for (int i = 0; i < size; i++) {
    Properties props = baseList.get(keys[i]);
    String error = props.getProperty("error", null);
    if (error != null) {
      out.println("<li class=\"error\">"+error+"</li>");
      continue;
    }
    String title = props.getProperty("title", null);
    if (title == null) title = props.getProperty("name", null);
    if (title == null) title =  keys[i];
    out.println("<li><a href=\""+keys[i]+"/\">"+title+"</a></li>");
  }
      %>
      </ul>
      <p>Projet réalisé sous la direction de <b>Didier Alexandre </b>2018-2020 <br/>
Idée et conception: <b>Motasem Alrahabi</b><br/>
Contributeurs: <b>Glenn Roe</b>, <b>Marine Riguet</b>, <b>Frédéric Glorieux</b><br/>
Développement: <b>Frédéric Glorieux</b></p>

<p>Présentation:<br/>
<a href="https://docs.google.com/presentation/d/1jrqjm-XuSFpCiIelS30eXD3Utrk15R9eIW9NbsnZ1go/edit#slide=id.g6e92d9f579_0_41">
https://docs.google.com/presentation/d/1jrqjm-XuSFpCiIelS30eXD3Utrk15R9eIW9NbsnZ1go/edit#slide=id.g6e92d9f579_0_41</a></p>

<p>Prise en main rapide:<br/>
<a href="https://docs.google.com/document/d/19h8oWHOMlJyMDIhRqxc0odLAjo-M9GoxDnWe3wwUFHM">
https://docs.google.com/document/d/19h8oWHOMlJyMDIhRqxc0odLAjo-M9GoxDnWe3wwUFHM</a></p>

<p>Guide détaillé:<br/>
<a href="https://obvil.huma-num.fr/obvie/static/aide.html">
https://obvil.huma-num.fr/obvie/static/aide.html</a></p>

<p>Pour indexer votre propre corpus, merci d'écrire un message à motasem.alrahabi@gmail.com</p>

    </article>
  </body>
</html>

