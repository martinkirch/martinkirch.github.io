title: Une fine sélection musicale pour Liquidsoap avec Beets
briefing: 2ème mouture du "Entasser les FLAC dans un répertoire ça marche, mais les prendre dans une discothèque c'est mieux"
date_time: 2020-06-04 22:00
slug: liquidsoap-musique-avec-beets-2
tags: liquidsoap, en_français
type: post





Dans le [premier épisode](/2020-05-05/liquidsoap-pige-et-automate-pour-radio-associative.html)
nous avions créé un automate radio basique,
qui piochait la musique dans certains répertoires.
C'est un bon début mais ce serait plus pratique de ne pas avoir à pre-sélectionner
par répertoires : même avec des sous-répertoires on peut se retrouver dupliquer certains titres, et changer d'avis sur le rangement sera compliqué après en avoir ajouté 1000.
Il faudrait plutôt une librairie musicale à notre radio :
quelque chose qui répertorie les titres et soit capable d'en sortir une sélection sur n'importe quels critères.

Dans cet article on va s'intéresser à [Beets](https://beets.io),
qui est un logiciel (en ligne de commande, encore !)
de gestion de bibliothèque musicale.
Il permet de ranger les fichiers par artiste/album et il vérifie les tags :
c'est le meilleur ami de votre discothèque.
Beets est déjà documenté et pas très long à installer
(voir [ici](https://beets.readthedocs.io/en/stable/guides/main.html#installing)).
Par contre il peut être long à comprendre et alimenter ;
mais comme nous allons voir ci-dessous, ça vaut le déplacement.
Pour vite passer à la suite (et surtout si vos fichiers sont déjà bien taggés)
lancez `beet import -A /home/moi/Musique` pour tout importer d'un coup...
mais disons qu'un jour il vous faudra lire sa documentation -
ci-dessous ne manquez pas non plus `drop2beets`.
Vous devrez avoir activé le plug-in `random` de beets,
c'est à dire que votre config beets contient au moins `random` sur la ligne qui commence par `plugins:`.

Coté Liquidsoap, **il vous faudra la version 1.4.2 ou supérieure**.

## Quelques exemples de requêtes Beets

Avant de commencer, voyons comment sélectionner des titres dans Beets : on lui fait des requêtes.
Vous pouvez tester vos requêtes en ligne de commande,
en tapant par exemple `beets random Titre`.
Ou encore avec la commande de recherche habituelle: `beet ls Artiste`.
Par défaut les requêtes (ici `Titre` et `Artiste`)se font sur le titre,
artiste, titre de l'album, artiste de l'album, genre ou commentaires.
Mais il y a d'autres champs, bien plus intéressants pour faire une playlist radio.

Les chansons francophones peuvent être sélectionnées avec
`language:fra`, qui fait une recherche dans Beets en filtrant les pistes taggués `fra` dans le champ `language`.
On peut aussi chercher par genre avec par exemple `genre:Rock` ;
attention `genre:Rock` recoupe aussi `Indie Rock`, `Punk Rock`...
Vous pouvez aussi créer une liste 80s avec `year:1980..1990` -
je vous laisse deviner pour les autres années.
Pour les intervalles, les valeurs avant ou après le `..` sont optionnelles,
si vous voulez laisser l'intervalle ouvert.

Il y a aussi des champs "techniques",
par exemple `added` qui est la date d'ajout du titre dans Beets.
On peut s'en servir pour retrouver les titres ajoutés il y a moins d'un mois avec `added:-1m..`,
ou encore il y a moins de 7 jours avec `added:-7d..`,
et plus d'un an avec `added:..-1y`.
Il y a [plein d'autres possibilités](https://beets.readthedocs.io/en/stable/reference/query.html),
tous ces critères peuvent être combinés
et vous pouvez aussi [tagger avec vos propres champs](https://beets.readthedocs.io/en/stable/guides/advanced.html#store-any-data-you-like).
Vous aurez donc de quoi créer des sources Liquidsoap qui piochent très précisément dans votre librairie.

Les informations sur un titre dans Beets vont donc au-delà des tags ID3.
Pour voir tout ce que stocke Beets sur un titre
(par exemple, un classique de Jimi Hendrix)
activez le plug-in `info` et tapez

    beet info -l All along the watchtower

Mais ces informations ne tombent pas du ciel.
Elles seront bonnes si Beets a réussi à recoller les titres avec [MusicBrainz](https://musicbrainz.org/)...
ce qui dépend du temps que vous avez passé à l'importation.
Vous préfèrerez peut-être importer avec le plug-in `drop2beets` présenté plus bas.
Mais d'abord, revenons à Liquidsoap.


## Beets comme source dynamique

Quand on cherche dans Beets (`beet ls`)
il peut nous donner les résultats sous la forme d'une liste de fichiers en précisant `-f '$path'`.
Autrement dit : il peut générer une playlist.
On peut aussi le faire avec `beet random`,
qui choisit aléatoirement un titre parmi les résultats d'une recherche.
Reste à appeler cette commande depuis Liquidsoap :
pour cela il y a `request.dynamic.list`.
Cette source est définie par une fonction ;
quand Liquidsoap a besoin de contenu pour cette source,
il appelle la fonction (soiler : qui va appeler `beet`),
qui doit retourner une liste de `request`.
On ne s'en est pas encore servi mais en gros une `request` correspond à un titre à lire.
Pour créer une source qui prend un morceau au hasard dans Beets,
au premier essai cela donne:

    :::ocaml
    def allo_beets() =
      list.map(fun(item) -> request.create(item),
        get_process_lines(
          "/home/me/path/to/beet random -f '$path'"
        )
      )
    end

    titre_aleatoire = request.dynamic.list(allo_beets)

`request.dynamic.list` va donc créer une source,
qui à chaque fois qu'elle doit préparer la prochaine piste va appeller la fonction Liquidsoap `allo_beats`.

Et dans cette fonction :

 * `list.map` retourne une liste à laquelle on a appliqué une fonction (le premier argument)
    à chaque élément d'une liste donnée (le second arguùent).
 * `fun(item) -> request.create(item)` est cette fonction : pour chaque élement `item` elle retourne `request.create(item)`.
 * get_process_lines` sert à appeler un programme, comme en ligne de commande.
 * on appelle `beet random`.
 * `-f '$path'` veut dire qu'on demande à Beets de lister chaque résultat par nom de fichier.

Autrement dit, avec cette fonction le chemin de fichier retourné par `beet random`
sera transformé en une `request` que va lire Liquidsoap.

C'est un bon début mais il nous faudrait plutôt une fonction qui transmette notre requête à `beets`,
pour pouvoir créer plusieurs sources avec la même fonction.
Pour cela, on va transformer l'appel à Beets en une fonction qui retourne une fonction directement utilisable par `request.dynamic.list`. Ce qui donne :

    :::ocaml
    def beets(arg="") =
      fun() -> list.map(fun(item) -> request.create(item),
        get_process_lines(
          "/home/me/path/to/beet random -f '$path' #{arg}"
        )
      )
    end

Notez qu'on a ajouté `arg` dans l'appel à `beet random`.
`arg` est optionnel (par défaut c'est `""`) donc cette variante s'utilise ainsi :

    :::ocaml
    musique = request.dynamic.list(beets())
    musique_recente = request.dynamic.list(beets("added:-1m.."))
    musique_FR = request.dynamic.list(beets("language:fra"))

Vous trouverez d'autres manières d'intégrer Beets à Liquidsoap
[dans la documentation](https://www.liquidsoap.info/doc-1.4.2/beets.html).


## drop2beets

Beets est conçu pour importer des albums complets,
et vérifie/corrige les tags de toutes les pistes en commençant l'import par une recherche dans
[MusicBrainz](https://musicbrainz.org/).
Ce niveau de rigueur peut coûter cher en temps, et en radio on va plutôt utiliser des singles,
qui s'importent avec l'option `-s` de `beet imp`.
Pour faire plus rapide,
j'ai créé un plug-in Beets qui importe un fichier dès qu'il est déplacé/copié
dans un répertoire de votre choix.
Oui, c'est tout à fait inspiré de la dropbox Rivendell développée par feu Tryphon.

Avec ce plug-in il est possible,
en écrivant un petit peu de Python,
de forcer certains tags du fichier en fonction du sous-répertoire dans lequel il a atteri.
Vous trouverez ce plug-in sur [GitHub](https://github.com/martinkirch/drop2beets),
et en radio asso française [cet exemple](https://github.com/martinkirch/drop2beets/blob/master/examples/force_genre_and_language_by_folder.py) correspond à l'usage qui consiste à
s'assurer de l'uniformité des tags de genre et de langue.


## Le plug-in Web

Beets est fourni avec un plug-in "Web", qui est une interface Web rudimentaire
pour faciliter la consultation de la librairie sur votre réseau local.
Les détails d'installation sont
[dans la documentation officielle](https://beets.readthedocs.io/en/stable/plugins/web.html).
Il créé un serveur HTTP léger
mais suffisant pour le réseau local d'une petite radio.
On recommande !

## Conclusion

Le script complet de la radio entamée la dernière fois, avec en plus
l'intégration de Beets, est téléchargeable [ici](02-radio.liq).
Cette intégration n'est pas nécessaire à notre automate,
et ajoute une couche de complexité à l'administration :
Beets nécessite de la pratique pour importer et nettoyer une discothèque complète.
Mais c'est bien pratique pour séparer le stockage et rangement de la musique de sa diffusion.
A partir de là on peut génerer des playlists correspondant à des styles,
artistes, années, etc.

_Cet article est le deuxième d'un série sur Liquidsoap ; retrouvez tous les articles de la série [ici](/tag/liquidsoap.html)._
