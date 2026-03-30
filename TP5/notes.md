Compilation

Terminal1: 
export SOCLIB_FB=HEADLESS
soclib-cc -p tp5.desc -t systemcass -o simul.x

Terminal2:
ssh -XY reicha
cd Document/S2/MULTI/TP5
make soft/
soclib-cc -p tp5.desc -t systemcass -o simul.x
./simul.x

Notes:

Bande passante: nombre maximum d'octets transférés par unité de temps.
Un nombre de processeur plus grand force le partage de la bande passante.
Le temps pour accéder au bus augmente.

Nouveaux périphériques:
FBF:"Frame Buffer Controller" (graphic display) -> affiche des images sur un écran
Plusieurs processeurs
TTY maintenant "character display"

1 processeur possède 1 TTY
Segment mémoire de tous les TTY, size = NPROCS*16 octets
car 4 registres de 32 bits, donc 4*4 octets = 16 octets. (32 bits = 4 octet)

Écran: 256*256 pixels, 256 niveau de gris
    Premier Tampon: (64Koctet, luminance)
        adresse de base: premier pixel de la première ligne
        adresse de base + 256: premier pixel de la deuxième ligne
        +1 = +1 octet
    Deuxième Tampon: (64Koctet, chrominance)
        (pas utilisés pour images en niveaux de gris)

    -> automate parcours les tampons à une fréquence de 25im/s!!
        (1/25 = 0,040 s =) toutes les 40ms !

Petits caches: 16 lignes de 8 mots, 1-Way associative (coresspondance directe)
(16lignes * 8mots * 4octets = 512 octets)

Main.c ->
    Échiquier 64 cases noires + 64 cases blanches = 128 cases
    1 case = 32*32 pixels = 1024 pixels
    => 2^(17) = 131 072 pixels

