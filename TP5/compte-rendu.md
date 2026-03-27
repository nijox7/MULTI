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
Il faut utiliser un appel système pour accéder au contrôleur Fram-Buffer car c'est un segment mémoire qui n'appartient pas à la zone allouée au processus utilisée par l'utilisateur. S'il tente d'y accéder sans appel système, celà provoquera une erreur de segmentation car le kernel refusera cet accès.

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
Coût miss écriture: 0

Les coûts ont des valeurs non entières car ils sont calculés par une moyenne.
<!-- TODO PAS SUR-->

### D3
<!-- TODO -->

## E - Exécution sur architecture multi-processeurs

### E1
On modifie le code du main.
On récupère d'abord le procid() avant la boucle, puis on traite la ligne si le numéro de la ligne a pour reste de la division par le nombre de processeur, le procid. Chaque processeur traitera les lignes qui lui correspondent.
```
for (int line = 0; line < NLINE; line += 1) { 
    // parcourt chaque ligne de pixel
        if (line%nprocs == n){
            for (int pixel = 0; pixel < NPIXEL; pixel += 1) { 
            // parcourt chaque pixel de la ligne
                buf[pixel] = build(pixel, line, 5);
                // détermine la couleur du pixel
            }
            if (fb_sync_write(256*line, &buf, 256)) {
                tty_printf(" !!! wrong transfer to frame buffer for line %d\n", line);
            }
            else {
                tty_printf(" - building line %d\n", line);
            }
        }
    }
```

### E2
Les piles d'exécutions des programmes doivent être disjointes pour éviter à un processeur d'écrire sur l'espace mémoire d'un autre processeur.
On modifie l'initialisation du pointeur de pile dans le code _reset.s_:
``` 
# initializes stack pointer
# initializes stack pointer
mfc0 $27, $15, 1        # récupère le numéro du processeur
la $29, seg_stack_base  # récupère l'adresse de la base de la pile

li $26, 0x10000         # r26 <= 64 000
addiu $27, $27, 1       # procid <= procid + 1
mult $27, $26           # res <= r27 * r26 = procid * 64 000
mflo $27                # r27 <= res, move from low (LSB de la multiplication)

addu $29, $29, $27      # stack_base <= stack_base + (procid+1) * 64000
```

On récupère le numéro de processeur afin de calculer le pointeur de la pile du processeur.
Celui-ci sera égal au nombre de processeurs multipliés par la taille de la pile (64 000 octets).

### E3
Le code binaire doit être recompilé si on change le nombre de processeur 
<!-- TODO POURQUOI??? -->
On doit mettre à jour le fichier config.h ce qui nécessite de recompiler le code binaire.

### E4

Lors de la simulation, 1 coeur n'a pas fonctionné.
> [GDB] CPU 0 (proc[0]) cycle:23151 PC:4008ec FAULT: bad address

1proc:  cycles=5277093  speedup=1

2procs: cycles=2954133  speedup=1.786342

4procs: cycles=1600839  speedup=3.296454

6procs: cycles=1517593  speedup=3.477278

8procs: cycles=1541276  speedup=3.423847

<!-- TODO EXPLIQUER POURQUOI LE SPEEDUP N'EST PAS LINÉAIRE (performance en augmentant le nombre de processeur) -->

Le nombre de processeur augmente, mais le nombre d'accès au bus aussi. Si le bus est accédé par trop de processeur en même temps, cela va ralentir le temps d'accès au bus et donc augmenter le nombre de cycles. Ceci fait que le speedup n'est pas linéaire et atteint un plafond au bout de 4 processeurs en simultanés.


## F - Évaluation des temps d'accès au bus

### F1
<!--TODO -->

### F2

1proc: IMISS COST= 16.0176, DMIS COST= 14.4359, WRITE COST = 0, ACCESS_TIME = 1, CPI = 1.40991

2procs: IMISS COST= 18.3077, DMIS COST=17.3568, WRITE COST = 0, ACCESS_TIME = 1.40719, CPI = 1.42738

4procs: IMISS COST=25.6168, DMIS COST=22.438, WRITE COST = 0.283372, ACCESS_TIME = 6.40546, CPI = 1.54386

6procs: IMISS COST= 43.9012, DMIS COST=38.1957, WRITE COST = 3.57146, ACCESS_TIME = 10.6535, CPI = 2.22041

8procs: IMISS COST= 60.9815, DMIS COST= 51.3061, WRITE COST = 7.52169, ACCESS_TIME = 15.6114, CPI = 2.95625

### F3
<!-- TODO -->


## G - Modélisation du comportement du bus