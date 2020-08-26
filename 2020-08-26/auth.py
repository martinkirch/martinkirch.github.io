#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Utilisation:

./auth.py UTILISATEUR MOT_DE_PASSE
    pour vérifier le mot de passe de l'utilisateur: écrit juste "ok" s'il est correct.

./auth.py --set UTILISATEUR MOT_DE_PASSE
    pour ajouter/mettre à jour un mot de passe
"""

import os, sys, crypt
from hmac import compare_digest
import syslog

FICHIER = "/home/martin/radio/liquidsoap/auth.txt"

def charge():
    try:
        with open(FICHIER) as fichier:
            lignes = fichier.readlines()
    except IOError:
        syslog.syslog(syslog.LOG_ERR, "Fichier %s introuvable, verifiez le script auth.py" % FICHIER)
        fichier = open(FICHIER, "w")
        fichier.close()
        os.chmod(FICHIER, 0o600)
        lignes = []
    utilisateurs = {}
    for ligne in lignes:
        colonnes = ligne.strip().split("\t")
        if len(colonnes) == 2:
            utilisateurs[colonnes[0]] = colonnes[1]
    return utilisateurs

def verif(utilisateur, mdp):
    existant = charge()
    if utilisateur not in existant:
        print("nope")
    elif compare_digest(crypt.crypt(mdp, existant[utilisateur]), existant[utilisateur]):
        print("ok")
    else:
        print("nope")

def enregistre(utilisateur, mdp):
    existant = charge()
    existant[utilisateur] = crypt.crypt(mdp)
    with open(FICHIER, 'w') as fichier:
        for util in existant:
            fichier.write(util)
            fichier.write("\t")
            fichier.write(existant[util])
            fichier.write("\n")


def main(argv):
    if len(argv) == 1:
        print(__doc__)
    elif len(argv) == 4 and argv[1] == "--set":
        enregistre(argv[2], argv[3])
    elif len(argv) == 3:
        verif(argv[1], argv[2])

if __name__ == '__main__':
    main(sys.argv)
