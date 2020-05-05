# le chemin vers le répertoire qui contient les fichiers de pige
# ne mettez aucun autre fichiers dedans !
REPERTOIRE_PIGE = "/mnt/pige"

# légalement, mettez au moins 31
NB_JOURS_DE_CONSERVATION_DE_LA_PIGE = 1

# nettoyage auto des vieux fichiers/répertoires
exec_at(freq=3600., pred={ true },
    fun () -> list.iter(fun(msg) -> log(msg, label="nettoyeur_de_pige"),
        list.append(
            get_process_lines("find #{REPERTOIRE_PIGE}/* -type f -mtime "
                ^ "+#{NB_JOURS_DE_CONSERVATION_DE_LA_PIGE} -delete"),
            get_process_lines("find #{REPERTOIRE_PIGE}/* -type d -empty -delete")
        )
    )
)

# le flux lui-même
output.file(%flac, # ou bien mp3, wav, vorbis, cf. https://www.liquidsoap.info/doc-1.4.0/encoding_formats.html

    "#{REPERTOIRE_PIGE}/%Y-%m-%d/%Hh%M_%S.flac",  # minutes/secondes en cas de redémarrage

    input.alsa(),
    reopen_when = {0m}  # minute 0 de chaque heure, donc chaque heure
)
