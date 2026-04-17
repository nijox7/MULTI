# Compte-rendu TP7

## Notes

DMA -> coprocesseur donc pas d'accès mémoire pour communiquer entre DMA et Processeur?\
    -> cible du processeur pour les commandes, mais pas pour le buffer qui enregistre l'image\
    -> initiateur du FrameBuffer pour envoyer l'image sur le bus en rafales (plus rapide que le logiciel)
    -> algorithme transformé en matériel (+++ rapide)
    -> capacité de stockage

Processeur -> écrit dans registres du DMA les paramètres (source, dest, size)

coprocesseur = travaille en parallèle

## B - Contrôleur DMA

### B1

- <b>SOURCE</b>: Accès en écriture ignoré si l'automate n'est pas en IDLE.

- <b>DEST</b>: Accès en écriture ignoré si l'automate n'est pas en IDLE.

- <b>LENGTH/STATUS</b>: Un accès en écriture initie le transfert du DMA suivant les registres SOURCE et DEST.\
Un accès en lecture donnera l'état actuel de l'automate du DMA.

- <b>RESET</b>: Accès en écriture arrête le transfert actuel du DMA et force l'automate à l'état IDLE. Cela permet également de reconnaître une IRQ. <!-- TODO pas compris derniere phrase -->

- <b>IRQ_DISABLED</b>: Si ce registre contient 1, les interruptions ne sont ignorées sur le DMA.

L'adresse de base du composant doit être alignée sur une frontière de bloc de 32 octet car seuls les 5 bits de poids faibles sont décodés et permettent d'adresses donc plus facilement les registres du DMA. Comme il y a 5 registres de 4 octets, on a 20 octet, en arrondissant à la puissance de 2 supérieur on arrive donc à 32 octets.

### B2
L'argument burst permet de spécifier le nombre maximum de mots que l'on veut transférer en 1 transfert en rafale.

### B3
Pour contrôler le contrôler le coprocesseur DMA, il faut deux automates. L'un pour gérer les transferts en rafales et les accès au bus, l'autre pour gérer l'état des commandes du processeur. Ceci permet de séparer deux tâches spécifiques indépendantes. L'automate Target indiquera donc au processeur si le DMA est capable de traiter sa requête ou s'il est occupé par exemple.

### B4
La bascule *r_stop* a pour fonction de signaler à l'automate Master d'arrêter son transfert s'il n'est pas en train de faire un transfert en rafale. Cela permet donc de synchroniser l'automate Master avec l'automate Target lorsque ce dernier  

La bascule *r_stop* permet de synchroniser les deux automates Target et Master.\
Target peut dire à Master de ne pas faire de transfert, dans ce cas la bascule *r_stop* est mise à 1 par Target.\
Cela permet également d'interrompre Master s'il est en train de faire un transfert. Mais un transfert en rafale ne peut être interrompu.\
Sinon Target peut dire à Master de faire un transfert en mettant *r_stop* à 0.

### B5

<!-- TODO mettre automate -->


## C - Architecture matérielle

### C1
La longueur d'une rafale en mots de 32 bits est de 16.\
L'avantage d'utiliser des grosses rafales est le nombre de cycles économisés par la réduction du nombre de requête au bus ainsi que les cycles servant à initier la transaction et la terminer.\
La conséquence de l'augmentation de la longueur de la rafale sur le matériel est <!-- TODO je ne sais pas??? Peut-être l'arbitre de bus mais c'est logiciel?? TIMEOUT??-->

### C2
L'adresse de base du composant DMA est 0x93000000.

Le numéro de cible du DMA pour le BCU est 6: 
>#define DMA_INDEX 6

Le numéro de maître du DMA pour le BCU est 1:
>bcu.p_req[nprocs]    (signal_req_dma);\
bcu.p_gnt[nprocs]    (signal_gnt_dma);

Le port d'entrée du composant ICU connecté au DMA est le port 0:
>IRQ_IN[0]    : DMA

## D - Application logicielle

### D1
Le composant qui effectue le transfert de pixel est le processeur lui-même.
L'appel car il utilise la fonction memcpy définit dans *common.h*.\
La fonction est donc bloquante car c'est une boucle while exécutée par le processeur.

### D2
Avec l'appel memcpy:

- Temps de construction de l'image: 2 432 848 cycles

- Temps d'affichage de l'image: 2 870 879 - 2 432 848 = 438 031 cycles

### D3
*fb_sync_write* fait appel à la fonction memcpy, qui s'éxecute sur le processeur, pour copier une zone mémoire utilisateur vers une destination donnée.

*fb_write* configure les registre du composant DMA pour qu'il transfère la mémoire à la manière de memcpy mais avec des transactions en rafales et en parallèle du processeur.

L'appel à fb_completed() permet de vérifier si le DMA est prêt à faire une nouvelle transaction, cela permet donc de ne pas effacer le buffer du DMA d'une transaction en cours.

### D4
Avec le DMA on obtient cette-fois ci:

- Temps de construction de l'image: 2 432 848 cycles

- Temps d'affichage de l'image: 2 476 462 - 2 432 848 = 43 614 cycles, soit 10 fois moins de temps d'affichage qu'avec memcpy!


### D5
Sans l'appel à *fb_completed()* et 1 mot par rafale:

- Temps de construction de l'image: 2 432 844 cycles

- Temps d'affichage de l'image: 2 436 605 - 2 432 844 = 3 761 cycles soit 1000 fois moins qu'en attendant avec fb_completed!

Le défaut est que lors de l'affichage des différentes étapes, sur le bords gauche de l'image, les carrés ne sont pas de la même taille que sur le reste de l'image.\
Ceci est dû au fait que le DMA est probablement trop lent par rapport au programme utilisateur qui n'attend plus que le DMA ait finit d'écrire dans le frame buffer avec l'appel à fb_completed(). Les images se mélangent donc car le programme demande au DMA d'écrire plusieur images en même temps. <!-- TODO peut etre pas sur, pas clair-->

### D6
La variable *_dma_busy* est mise à 1 dans la fonction *_fb_read* et *_fb_write*.
Elle est mise à 0 dans la fonction *_isr_dma*. <!-- TODO où est déclarée _dma_busy?? -->

## E - Pipeline logiciel

### E1
Pour passer de la période *(n)* à la période *(n+1)* il faut vérifier que la constructions et l'affichage soit finit dans les deux buffers pour ne pas avoir d'accès concurrents. Comme l'affichage est beaucoup plus rapide que la construction on doit vérifier seulement que la constructions est finie. <!-- TODO pas sur?? -->

### E2
La durée 

- Temps de construction de l'image: 3 104 741 cycles

- Temps d'affichage de l'image: 6 218 657 -  6 215 105 = 3 552 cycles

On a un temps d'affichage un peu moins long de 2 000 cycles environ.\
Le gain n'est pas très significatif car l'affichage est beaucoup plus court que la construction de l'image d'environ un facteur 1 000.\
La parallèlisation de ces deux tâches ne provoque donc pas un gain significatif.

12 345 946 cycles DMA

15 606 323 cycles PIPE

## F - Traitement d'erreurs

### F1




<!-- TODO ACTIVER -SNOOP 1!!! -->
<!-- TODO ACTIVER -SNOOP 1!!! -->
<!-- TODO ACTIVER -SNOOP 1!!! -->