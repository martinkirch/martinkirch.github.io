## Un automate radio basique pour radio associative avec Liquidsoap
## Martin Kirchgessner, 2020
## https://martinkirch.github.io/

# Coté syntaxe : les espaces ne sont pas importants, ni l'ordre des paramètres nommés (comme id="truc")
# pour le reste... fermez bien les parenthèses, crochets et autres accolades !


############################ EMISSIONS ######################################


emissions = switch(id="emissions", [
  ({12h00-12h30}, single(id="superemission", "/home/radio/emissions/superemission/EpisodeCourant.flac")),
  ({ 8h00-9h00},  single(id="matinale",      "/home/radio/emissions/matinale/EpisodeCourant.flac")),
  ({18h00-19h00}, single(id="apero",         "/home/radio/emissions/apero/EpisodeCourant.flac"))
])



########################## Tambouille de musiques/quotas/jingles ###################



# On recharge toutes les heures le contenu des playlists, en cas d'ajout/suppression de fichiers
musique         = playlist(reload=3600, id="musique",         "/home/radio/Musique/TOUT")
musique_FR      = playlist(reload=3600, id="musique_FR",      "/home/radio/Musique/FR")
musique_recente = playlist(reload=3600, id="musique_recente", "/home/radio/Musique/AIRPLAY/")

playlist_quota = mksafe(id="playlist_quota", random(
  [        musique, musique_FR, musique_recente],
  weights=[40,      35,         25]
))

semaine_musicale = switch(id="semaine_musical", [
  ({ (1w or 2w or 3w or 4w or 5w) and 6h30-22h30 }, playlist_quota),
  ({ (6w or 7w) and 8h-22h30 }, playlist_quota),
  ({ true }, mksafe(musique)) # switch n'est safe que s'il termine sur une source safe
])



def crossfade_3s(a,b)
  add(normalize=false,
      [ fade.in(duration=3.,b),
        fade.out(duration=3.,a) ])
end

grille = fallback([emissions, semaine_musicale],
  transitions=[crossfade_3s, crossfade_3s],
  track_sensitive=false, id="grille")


# 780 = au moins 13 minutes de délai entre les jingles
# "delay" compte en secondes et c'est forcément un flottant d'ou le point obligatoire
jingles = delay(780., id="jingles",
    playlist.safe("/home/radio/jingles", mode="random", reload_mode="watch")
)

# a la fin de chaque track, va piocher un jingle s'il est dispo (après lecture, il n'est pas dispo)
grille_avec_jingle = fallback([jingles, grille], id="grille_avec_jingle")



##################### SORTIES ################################################


# s'il y a plus de 10 secondes à -50dB, on zappe à la piste suivante !
radio = skip_blank(grille_avec_jingle, max_blank=10., threshold=-50.)

output.alsa(radio, id="alsa")

clock.assign_new(id="icecast", [
    output.icecast(%vorbis, # ou bien mp3, wav, flac, cf. https://www.liquidsoap.info/doc-1.4.0/encoding_formats.html
        host = "localhost",
        port = 8000,
        password = "secret",
        mount = "maradio.ogg", # donc ce sera sur http://localhost:8000/maradio.ogg
        mksafe(buffer(radio))
    )
])
