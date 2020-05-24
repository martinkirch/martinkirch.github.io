title: Des playlists musicales futées pour Liquidsoap avec Beets
briefing: Entasser les FLAC dans un répertoire ça marche, mais les prendre dans une discothèque c'est mieux.
date_time: 2020-05-24 22:00
slug: liquidsoap-musique-avec-beets
tags: liquidsoap, en_français
type: post

Dans le [premier épisode](/TODO) nous avions créé un automate radio basique,
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

Cet article va s'intéresser à l'intégration avec Liquidsoap.
Beets est déjà documenté et pas très long à installer
(voir [ici](https://beets.readthedocs.io/en/stable/guides/main.html#installing)).
Il peut être long à comprendre et alimenter, c'est vrai.
Pour vite passer à la suite (et surtout si vos fichiers sont déjà bien taggés)
lancez `beet import -A /home/moi/Musique` pour tout importer d'un coup...
mais disons qu'un jour il vous faudra lire sa documentation.

## Beets comme source de playlists

Quand on cherche dans Beets (`beet ls`)
il peut nous donner les résultats sous la forme d'une liste de fichiers, en précisant `-f '$path'`.
Autrement dit : il peut générer une playlist.
Surtout avec `beet random`,
qui choisit aléatoirement un titre parmi les résultats d'une recherche.
Nous allons donc l'intégrer comme un protocole Liquidsoap.

Qu'est-ce qu'un protocole ?
Par exemple quand on écrit 
`playlist("http://live.campusgrenoble.org:9000/rcg112.m3u")` le protocole c'est `http`.
Nous allons ajouter un protocole qui s'appellera `beets`, qui appellera `beet random`.
Par défaut `beet random` ne sélectionne qu'un titre,
mais en utilisant l'option `-t N` il peut en sélectionner plusieurs, totalisant au plus N minutes.
On pourra donc générer presque une heure de playlist "tournante", toutes les heures, en appelant `playlist("beets:-t60", mode="normal", reload=3600)`.
On précisera `normal` car par défaut `playlist` parcoure la playlist aléatoirement,
or l'aléa est déjà assuré par `beets random`.


Liquidsoap permet d'ajouter un protocole en lui donnant un petit nom et une
fonction qui décidera que faire de ce qu'il y a après le `:` qui suit le nom du protocole.
Pour ce qui nous intéresse, on peut définir cette fonction puis appeler `add_protocol` ainsi :

    :::ocaml
    def beets_protocol(~rlog,~maxtime,arg) =
      tmp_playlist = file.temp("beetsplaylist", ".m3u8")
      ignore(get_process_lines(
        "/home/martin/beets/bin/beet random -f '$path' #{arg} > #{tmp_playlist}"
      ))
      [tmp_playlist]
    end
    add_protocol("beets", beets_protocol)

Dans la fonction, remplacez `/home/martin/beets/bin/beet` par le chemin complet chez vous
(affiché par la commande `which beet`).
A part cela vous pouvez utilisez la fonction telle quelle,
mais elle mérite quelques explications :

 * Notre fonction s'appelle `beets_protocol` ;
   Liquidsoap impose que les fonctions d'interprétation des protocoles aient les
   arguments `~rlog,~maxtime,arg`, même si on ne va se servir que d'`arg`. 
 * La playlist sera générée dans un fichier temporaire, `tmp_playlist`,
   qui d'après ce qu'on a donné à `file.temp` va ressembler à `/tmp/beetsplaylist***.m3u8`.
 * `ignore(get_process_lines(` sert à appeler un programme, comme en ligne de commande.
 * on appelle `beet random`.
 * `-f '$path'` veut dire qu'on demande à Beets de lister chaque résultat par nom de fichier.
 * `arg` est ce qui est après les `:` quand on utilise le protocole.
   Par exemple si on écrit `playlist("beets:-t60 genre:Rock")`,
   alors `arg` contiendra `-t60 genre:Rock`.
 * ` > #{tmp_playlist}` redirige la sortie de `beet` vers le fichier dont le nom est dans `tmp_playlist` (donc le `/tmp/beetsplaylist***.m3u8`).
 * `[tmp_playlist]` est une liste qui ne contient qu'un élément :
   le nom du fichier temporaire. Et comme c'est la dernière instruction de la fonction,
   c'est cette liste qui sera retournée par la fonction. C'est donc depuis ce fichier que Liquidsoap va effectivement charger la playlist.
 * `add_protocol("beets", beets_protocol)` est l'instruction à partir de laquelle toute les requêtes commençant par `beets:` seront tranmise à notre fonction `beets_protocol`.

Si on laisse tourner longtemps un script utilisant ce protocole, on va finir par remplir `/tmp` de nos playlists temporaires.
Ce n'est pas très pratique alors ajoutons aussi une fonction qui va régulièrement faire le ménage :

    :::ocaml
    exec_at(freq=3600., pred={ true },
      fun () -> list.iter(fun(msg) -> log(msg, label="nettoyeur_playlists"),
        get_process_lines("find /tmp -iname beetsplaylist*m3u8 -mtime +0 -delete"),
      )
    )

A partir de là,
on peut donc faire une source infinie de musique aléatoire avec
`playlist("beets:-t60", mode="normal", reload=3600)`.
Mais en fait cette boucle musicale n'est pas vraiment suffisante :

* `beets random -t60` génère une liste dont la longueur _maximale_ est de 60 minutes,
souvent il ne trouve pas de quoi boucher les dernières minutes/secondes.
Par conséquent, si on ne la rafraîchit que toutes les heures, le premier morceau
risque de rejouer en fin d'heure.
* En plus, sur le long terme les morceaux courts vont être joués plus souvent
que les autres car ce sont les seuls avec lesquels Beets parviendra à boucher
les fins de playlists.

Pour éviter ceux deux désagréments vous pouvez augmenter le `60` ou réduire le `3600` ...
ou bien alterner régulièrement avec d'autres playlists.
Comme on l'a vu dans l'article précédent, avec `random` on peut passer d'une playlist à l'autre (tout, francophone, récent, etc.).

## Quelques exemples de playlists en `beets:`

Les chansons francophones peuvent être sélectionnées avec
`language:fra`, qui fait une recherche dans Beets en filtrant les pistes taggués `fra` dans le champ `language`.

Il y a d'autres champs, notamment `genre` ;
on pourrait générer une heure de rock avec `playlist("beets:-t60 genre:Rock")`.
Attention `genre:Rock` recoupe aussi `Indie Rock`, `Punk Rock`... 
Vous pouvez tester vos sélecteurs `beets` en essayant directement depuis
la ligne de commande, en tapant par exemple `beets random -f '$genre $path' -t60 genre:Rock`
(on ajoute `$genre` au `-f` pour voir ce qu'il contient vraiment).
Ou encore avec la commande de recherche habituelle: `beet ls genre:Rock`.


Il y a aussi des champs "techniques",
par exemple `added` qui est la date d'ajout du titre dans Beets.
On peut s'en servir pour retrouver les titres ajoutés il y a moins d'un mois avec `added:-1m..`,
ou encore il y a moins de 7 jours avec `added:-7d..`
Il y a [plein d'autres possibilités](https://beets.readthedocs.io/en/stable/reference/query.html),
tous ces critères peuvent être combinés
et vous pouvez aussi [tagger avec vos propres champs](https://beets.readthedocs.io/en/stable/guides/advanced.html#store-any-data-you-like).
Vous aurez donc de quoi créer des sources Liquidsoap qui piochent très précisément dans votre librairie.

Les informations sur un titre dans Beets vont au-delà des tags ID3.
Pour voir tout ce que stocke Beets sur un titre
(par exemple, un classique de Jimi Hendrix)
tapez

    beet info -l All along the watchtower

Mais ces informations ne tombent pas du ciel.
Elles seront bonnes si Beets a réussi à recoller les titres avec [MusicBrainz](https://musicbrainz.org/)...
ce qui dépend du temps que vous avez passé à l'importation.
Vous préfèrerez peut-être le plug-in suivant.


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
