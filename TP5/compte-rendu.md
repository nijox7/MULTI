# Compte-rendu TP5

## A - Objectifs

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

## B - Architecture matérielle

### B1
Les arguments du constructeur de PibusFrameBuffer:

name -> le nom de l'instance
latency -> le temps de réponse du périphérique en nombre de cycle+1
width -> nombre de pixel par ligne
height -> nombre de lignes de pixel(s)

### B2
La longueur du segment mémoire associé à ce composant est de 2*(widht*height) octets car il possède deux tampons de 64Koctets.
On a donc une taille de 2*(256*256) = 2*64Koctets = 128Koctets.

## C

### C1
Il faut utiliser un appel système pour accéder au contrôleur Fram-Buffer car c'est un segment mémoire qui n'appartient pas à la zone alloué au processus utilisé par l'utilisateur. S'il tente d'y accéder sans appel système, celà provoquera une erreur de segmentation car le kernel refusera cet accès.

### C2
On écrit une ligne complète dans un tableau intermédiaire pour limiter l'accès au bus.
bus data: 32bits
Comme un pixel est codé sur 8 bits (256 niveaux de gris), on gacherait la capacité du bus qui est de 32 bits.
De plus, si un autre processus veut accéder au bus en même temps, il est plus intéressant de limiter le nombre d'accès mémoire pour éviter les temps d'attentes.

### C3
fb_syn_write permet de copier length octet(s) d'un buffer à l'adresse de base du périphérique FBF + l'offset.

offset -> décalage par rapport à l'adresse de base de FBF
buffer -> adresse du buffer à copier
length -> nombre d'octet à copier

## D - Caractérisation de l'application logicielle

### D1
Le nombre de cycles nécessaires pour afficher l'image avec 1 processeur est de 5277093.
3 785 738 instructions ont été éxecutées.
Le CPI est de 1,39.

### D2
Pourcentage d'écritures: 13,35%
Pourcentage de lectures de données: 25,71%
Taux de miss sur cache d'instructions: 0,97%
Taux de miss sur cache de données: 1,06%
Coût miss cache instruction: 15,91
Coût miss cache de données: 14,74

Les coûts ont des valeurs non entières car ils sont calculés par une moyenne.
<!-- TODO PAS SUR-->

### D3
<!-- TODO -->

## E - Exécution sur architecture multi-processeurs

### E1

