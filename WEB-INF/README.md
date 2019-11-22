# Obvue, cuisine

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


