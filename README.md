
 ######################################################
 #                                                    #
 #   PROJET 2 : Rendu 1                               #
 #                                                    #
 #   Maxime Lesourd                                   #
 #   Yassine HAMOUDI                                  #
 #                                                    #
 #                                                    #
 ######################################################
 #                                                    #
 #   SOMMAIRE                                         #
 #                                                    #
 #   0 - Compilation et exécution                     #
 #   1 - Structures de données                        #
 #   1 - Prétraitement de l'entrée                    #
 #   2 - Algorithmes                                  #
 #   3 - Réponse à la partie 2                        #      
 #   4 - Performances                                 #
 #   4 - Optimisations                                #
 #   5 - Répartition des tâches                       #
 #                                                    #
 ######################################################


Compilation et exécution    
========================

Pour compiler, entrer : 

    make

Pour exécuter le programme sur un fichier ex.cnf, entrer : 

    ./resol ex.cnf 

Pour afficher les informations sur le déroulement de l'algorithme :

    ./resol -d n ex.cnf

où d est un entier positif définissant le niveau de détail de la description

Pour générer une formule de n clauses de taille l avec k variables dans out.cnf :

    ./gen k l n > out.cnf

Pour le résoudre à la volée :

    ./gen k l n > ./resol 

Pour utiliser l'algorithme watched literals :

    ./resol_wl ex.cnf

Note: resol_wl accepte les mêmes options que resol

Structures de données
=====================

Les structures suivantes sont utilisées par l'algorithme :

clause.ml:
---------

* variable : Les variables sont des entiers

* varset : objet représentant un ensemble de variables. Permet de cacher temporairement des variables.

* clause : une clause est un objet qui contient 2 varset : 
              * vpos : l'ensemble des variables apparaissant positivement dans la clause 
              * vneg : l'ensemble des variables apparaissant négativement dans la clause
           Par exemple, pour la clause 1 2 -3, on a vpos={1,2} et vneg={3}

Les assignations de valeurs dans la clause se traduisent en un passage des littéraux faux dans la partie cachée.

Note : l'objet clause contient aussi des champs spécifiques à l'algorithme des watched literals, ils seront expliqués plus loin.

formule.ml:
-----------

* clauseset : objet représentant un ensemble de clauses. Permet de cacher temporairement des clauses.
              Note : On compare les clauses en leur assignant un identifiant unique à leur création.

* 'a vartable : table d'association polymorphique sur les variables

* formule : une formule est un objet qui contient 4 valeurs :
              * nb_var : le nombre de variables apparaissant dans la formule
              * clauses : clauseset contenant les clauses formant la formule
              * paris : un bool vartable correspondant à une assignation partielle des variables
              * x : un compteur permettant de numéroter les clauses

formule_dpll.ml:
----------------

* occurences : 2 vartable de clauseset permettant de savoir où apparait chaque variable selon sa positivité.
               Si aucun pari n'est fait sur la variable ils contiennent la liste des clauses visibles où elle apparait.
               Si un pari a été fait ils contiennent la liste de clauses cachées qu'il faudra restaurer en cas de backtrack.

Les assignations de valeur dans la formule se traduisent en un passage des clauses validées par le littéral dans la partie cachée
des clauses, une modification des listes d'occurences pour garantir la propriété citée précédemment et une assignation dans les clauses. 

Algorithme DPLL
===============

L'algorithme DPLL est implémenté comme une alternance de phases de propagation de contraintes et de paris sur des variables libres.

La variable à assigner est choisie comme la première variable non assignée.

La propagation des contraintes est accélérée par la connaissance par la formule des clauses contenant la variable assignée,
On évite ainsi de parcourir toutes les clauses. 

Algorithme Watched Literals
===========================


Générateur
==========

Un générateur de clauses est fourni avec le solveur


Analyse des performances du programme
=====================================








