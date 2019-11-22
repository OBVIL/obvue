# Obvue

Obvue est une application web Java pour explorer des textes en XML/TEI,
basée sur le moteur d’indexation sur [Lucene java](https://lucene.apache.org/core/),
piloté par [Alix](https://github.com/oeuvres/Alix), pour la lemmatisation
et les statistiques lexicales.

![Copie d’écran](static/doc/gout-critique.png)

## Dossiers

* static — ressources servies sans modification
  * vendor — librairies importées à ne pas modifier
  * img — ressources graphiques
  * doc — aide
  * js — javascript de l’interface
* jsp — pages dynamiques
* WEB-INF — [servlet standard]
  * web.xml — [servlet standard]
  * lib — [servlet standard] jars
  * classes — [servlet standard] classes compilées
  * ext — autres librairies (pour la compilation et l’indexation)
  * java — sources java partagées Obvue
  * bases — [requis] dossier contenant la déclaration des bases et leur index lucene
    * base1.xml — déclaration d’une base qui répondra à {servletContext}/base1/
    * base2.xml — déclaration d’une base qui répondra à {servletContext}/base2/
    * base.sh — script d’aide pour lancer l’indexation d’une base (voire plusieurs)


