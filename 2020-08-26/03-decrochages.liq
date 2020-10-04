## Un automate radio basique pour radio associative avec Liquidsoap + Beets + Décrochages
## Martin Kirchgessner, 2020
## https://martinkirch.github.io/

# Coté syntaxe : les espaces ne sont pas importants, ni l'ordre des paramètres nommés (comme id="truc")
# pour le reste... fermez bien les parenthèses, crochets et autres accolades !

BEET = "/home/martin/beets/bin/beet"

set("server.telnet", true)
set("server.telnet.bind_addr", "127.0.0.1") # commandes de serveur faisables uniquement localement

set("harbor.bind_addrs", ["192.168.1.166"]) # optionnel. restreint au réseau local.


############################ EMISSIONS ######################################


emissions = switch(id="emissions", [
  ({12h00-12h30}, playlist(reload_mode="watch", mode="normal", id="superemission", "/home/radio/emissions/superemission")),
  ({ 8h00-9h00},  playlist(reload_mode="watch", mode="normal", id="matinale",      "/home/radio/emissions/matinale")),
  ({18h00-19h00}, playlist(reload_mode="watch", mode="normal", id="apero",         "/home/radio/emissions/apero"))
])



########################## Lien avec la lib musicale : Beets ##################

def beets(arg="") =
  fun() -> list.map(fun(item) -> request.create(item),
    get_process_lines(
      "#{BEET} random -f '$path' #{arg}"
    )
  )
end

### DECROCHAGE : Campus Grenoble de 15 à 16h tous les jours ####################

rcg = input.http(id="rcg", "http://live.campusgrenoble.org:9000/rcg112",
  autostart=false, buffer=3., max=30.)
exec_at(pred={ 15h00m00s },
  { list.iter(log(label="server_driver"), server.execute("rcg.start")) }
)
exec_at(pred={ 16h00m00s },
  { list.iter(log(label="server_driver"), server.execute("rcg.stop")) }
)

### DIRECT EXTERIEUR

def auth(user,password) = 
  ret = get_process_output("/home/radio/auth.py #{user} #{password}")
  if string.trim(ret) == "ok" then
    true
  else
    false
  end
end

direct_exterieur = input.harbor(id="direct_exterieur",
  buffer=2.,
  max=10.,
  auth=auth,
  port=8005,
  "direct"  # mountpoint name
)

########################## Tambouille de musiques/quotas/jingles ###################

musique         = request.dynamic.list(id="musique", beets())
musique_FR      = request.dynamic.list(id="musique_FR", beets("language:fra"))
musique_recente = request.dynamic.list(id="musique_recente", beets("added:-1m.."))

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

grille = fallback([direct_exterieur, rcg, emissions, semaine_musicale],
  transitions=[crossfade_3s, crossfade_3s, crossfade_3s, crossfade_3s],
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
