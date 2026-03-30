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
fb_syn_write permet de copier length octet(s) d'un buffer à l'adresse de base du périphérique FBF + l'offset. Voici la description des arguments:

offset -> décalage par rapport à l'adresse de base de FBF

buffer -> adresse du buffer à copier

length -> nombre d'octet à copier


## D - Caractérisation de l'application logicielle

### D1
Le nombre de cycles nécessaires pour afficher l'image avec 1 processeur est de 5 277 093.\
3 785 738 instructions ont été éxecutées.\
Le CPI est de 1,39.

### D2
Pourcentage d'écritures: 13,35%\
Pourcentage de lectures de données: 25,71%\
Taux de miss sur cache d'instructions: 0,97%\
Taux de miss sur cache de données: 1,06%\
Coût miss cache instruction: 15,91\
Coût miss cache de données: 14,74\
Coût lecture de donnée non-cachable: 6\
Coût miss écriture: 0

Les coûts ont des valeurs non entières car ils sont calculés par une moyenne. Ils ne sont donc pas constants.

### D3
On a donc (en nombre d'évènement par instructions):\
0,97% de transaction IMISS\
1,06% de transactions DMISS\
13% d'écritures\
0,12% de lecture de données non-cachables\
Pour un total de 3 743 086 instructions

En calculant proportionellement multipliant le nombre total d'instruction par chacun des pourcentages, on a donc environ en nombre de transactions:

36 307 transactions IMISS\
39 676 transactions DMISS\
486 601 transactions d'écritures\
4 491 transactions de données non-cachables

On remarque que le nombre de transactions sur le cache de données est à peu près équivalent à celui sur le cache d'instructions.
D'autre part, on a beaucoup de transactions d'écritures qui correspondent probablement à l'écriture des pixels, et très peu de transactions de données non-cachables.


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
Le code binaire doit être recompilé si on change le nombre de processeur.
On doit mettre à jour le fichier config.h ce qui nécessite de recompiler le code binaire.
Ceci est du au fait que la variable N_PROCS doit être changée afin de répartir le travail entre les processeurs dans l'application.

### E4
Lors de la simulation, 1 coeur n'a pas fonctionné.
> [GDB] CPU 0 (proc[0]) cycle:23151 PC:4008ec FAULT: bad address
C'était du au code reset.s qui n'était pas fait correctement.
Voici les mesures prises des simulations avec différents nombres de processeurs:

1 processeur:  cycles=5277093  speedup=1

2 processeurs: cycles=2954133  speedup=1.786342

4 processeurs: cycles=1600839  speedup=3.296454

6 processeurs: cycles=1517593  speedup=3.477278

8 processeurs: cycles=1541276  speedup=3.423847

|       |1proc   | 2procs | 4procs | 6procs | 8procs |
|:------|:-----: |:-----: |:-----: |:-----: |:------:|
|cycles |5277093 |2954133 |1600839 |1517593 |541276  |
|speedup|1       |1.786342|3.296454|3.477278|3.423847|

Le nombre de processeur augmente, mais le nombre d'accès au bus aussi. Si le bus est accédé par trop de processeur en même temps, cela va ralentir le temps d'accès au bus et donc augmenter le nombre de cycles. Ceci fait que le speedup n'est pas linéaire et atteint un plafond au bout de 4 processeurs en simultanés.


## F - Évaluation des temps d'accès au bus 
Il faut effectuer la mesure au moment où l'application se termine car, on veut mesurer les temps d'accès au bus en moyenne pendant l'exécution de l'application.
Si l'application se termine, et qu'on continue de mesurer ces valeurs, elles vont être faussées puisque les processeurs ne font plus le travail demandé par l'application.
Si on prend la mesure avant la fin, elle pourrait être différente de la mesure à la fin de l'application.

### F2

ACCES_TIME correspond au nombre de cycles d'attente des processeurs divisé par le nombre de requêtes effectuées sur le bus.

|NPROCS         |1          |2          |4          |6          |8          |
|:------        |:---:      |:----:     |:----:     |:----:     |:----:     |
|IMISS COST     |16.01      |18.31      |25.62      |43.90      |60.98      |   
|DMISS COST     |14.44      |17.36      |22.44      |38.20      |51.31      | 
|WRITE COST     |0          |0          |0.28       |3.57       |7.52       | 
|ACCESS TIME    |1          |1.40       |6.40       |10.65      |15.61      | 
|CPI            |1.40       |1.42       |1.54       |2.22       |2.96       | 

Le CPI augmente avec le nombre de processeurs.\
Le temps d'accès au bus augmente fortement avec l'augmentation du nombre de processeurs.\
Les coûts de miss sur les cache d'instructions et de données augmentent.\
Le coût d'écriture augmente fortement également.


### F3
On voit donc que l'augmentation du nombre de processeurs, augmente fortement le temps d'accès au bus. Ce temps d'accès se répercute sur les coûts des MISS  sur les caches, le coût d'écriture et le nombre de cycle par instructions.

Comme on a beaucoup plus d'écritures que de MISS, l'augmentation du CPI est probablement principalement dûe aux écritures qui sont retardées par le temps d'accès au bus.

## G - Modélisation du comportement du bus

### G1
On rappelle que le PiBus permet des transferts de 1 mot car le signal Data est sur 32 bits.

IMISS et DMISS:\
Comme on fait un Miss, on doit lire une ligne de cache. On a 8 mots par ligne de cache. On a donc 8 cycles pour envoyer les 8 adresses, un cycle pour lire la 8ème et dernière donnée et 1 "cycle mort".\
Le nombre de cycle total est de 10 cycles si l'esclave est prêt à chaque fois.

UNC et WRITE:\
Ces deux transactions sont composées d'un seul transfert de 1 mot. Donc elles 1 cycle pour l'adresse, 1 cycle pour la donnée et 1 "cycle mort".\
Le nombre de cycles total est de 3 cycles si l'esclave est prêt à chaque fois.

### G2

Calculs:

Fréquences:\
(On divise le nombre de transactions par le nombre de cycles)\
IMISS: 36 307 / 5 277 093 = 6,8 * 10^(-3)\
DMISS: 39 676 / 5 277 093 = 7,5 * 10^(-3)\
WRITE: 486 601 / 5 277 093 = 9,2 * 10^(-2x)\
UNC: 4 491 / 5 277 093 = 8,5 * 10^(-4)

Temps d'occupation:\
(On multiplie le nombre de transactions par le coût + 1 de celle-ci)\
IMISS: 36 307 * (15,91 + 1) = 613 951,3\
DMISS: 39 676 * (14,74 + 1) = 624 500,2\
WRITE: 486 601 * (0 + 1) = 486 601\
UNC: 4 491 * (6 + 1) = 31 437

|     | Temps_occupation | Fréquence    |
|:----|:----------------:|:------------:|
|IMISS| 10               | 6,8 * 10^(-3)|
|DMISS| 10               | 7,5 * 10^(-3)|
|WRITE| 3                | 9,2 * 10^(-2)|
|UNC  | 3                | 8,5 * 10^(-4)|


### G3
On multiplie chaque fréquence de chaque type de transaction par sont temps d'occupation puis on en fait la somme:
$$TauxOccupationBus = \sum_{i} Frequence_i TempsOccupation_i$$
Le résultat de ce calcul est le taux d'occupation du bus par tous les types de transaction d'un processeur.

En faisant ce calcul on obtient: 
$$TauxOccupationBus_{1 processeur} \approx 0,422 = 42,2\%$$
Si on avait donc 2 processeur, on aurait $84,4\%$. Avec 4 processeurs on atteint $128,8\%$, on dépasse $100\%$ de transactions par cycle, il y a donc une saturation du bus.\
Le bus commence à saturer donc à partir de 4 processeurs, ce qui est cohérrent avec nos résultats précédents.