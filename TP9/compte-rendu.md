# Compte-rendu TP9

## Notes

## C - Application producteur / consommateur

### C1
Sur le terminal TTY[0] on devrait voir les messages:\
> transmitted value : 1     temporisation = 100

...
> transmitted value : 49    temporisation = 100

Sur le terminal TTY[1] on devrait voir les messages:\
> received value : 1      temporisation = 100

...
> received value : 49     temporisation = 100

On ne sait pas si le TTY[1] va afficher de 0 à 48 ou de 1 à 49 ou autre chose.\
Comme le TTY[0] et le TTY[1] ont les même délais, cela dépend de si le TTY[0] est plus rapide ou plus lent que le TTY[1].

### C2
Question C2 : Complétez le code assembleur contenu dans le fichier reset.s pour que les tâches producer et consumer soient lancées sur les processeurs 0 et 1 respectivement.

### C3
- PRODUCER_DELAY=100, CONSUMER_DELAY=100: comme les délais sont égaux, les valeurs affichées sont des fois les mêmes 2 fois de suite pour le consumer. Pour le producer, les valeurs sont la suite de 0 à 49. Ceci est dût au fait que des fois le consumer est plus rapide que le producer ou inversement.

- PRODUCER_DELAY = 10, CONSUMER_DELAY = 1000: Comme le producer est plus rapide que le consumer, les valeurs ne sont jamais 2 fois les mêmes pour le consumer, sauf lorsque le producer atteint 49, le consumer n'affiche alors que 49.\
Le consumer saute également certaines valeurs qu'il n'a pas eu le temps d'afficher car le producer est plus rapide.

- PRODUCER_DELAY = 1000, CONSUMER_DELAY = 10: Le consumer est plus rapide que le producer, certaines valeurs sont donc affichées plusieurs fois à la suite et le consumer finit son programme avant le producer car sa dernière valeur reçue est 37 alors que le producer va jusqu'à 49.

On remarque donc que en changeant le délai les valeurs nous montrent lorsque un des deux processeurs est plus rapide que l'autre par le fait qu'ils sont désynchronisés par leur délai.\
Il est donc nécessaire d'implémenté un mécanisme de synchronisation s'il l'on veut les synchroniser.


## D - Synchronisation par bascule SET/RESET

### D1
Il n'y a pas de risque d'incohérence liée aux accès concurrents à la variable *sync* car celle-ci ne peut pas avoir d'accès concurrents en écriture. De plus, lorsque l'un a modifié la variable sync, il ne peut pas la modifier tant que l'autre ne l'a pas modifié, il ne peut donc y a voir de problème d'incohérence.
<!-- TODO peut-être il y a une meilleure raison jsp -->

### D2
Avec synchronisation:
- 530 236 cycles, PRODUCER_DELAY=100, CONSUMER_DELAY=100
- 476 290 cycles, PRODUCER_DELAY=10, CONSUMER_DELAY=100
- 476 245 cycles, PRODUCER_DELAY=100, CONSUMER_DELAY=10

Sans synchronisation: 
- 272 833 cycles, PRODUCER_DELAY=100, CONSUMER_DELAY=100

### D3
La cachabilité des variables *sync* et *buf* introduit un risque de dysfonctionnement car si par exemple PROC0 LIT sync et l'enregistre dans son cache, si PROC1 écrit sync, PROC0 lors de sa prochaine lecture fera un HIT sur le cache et PROC0 ne verra pas la nouvelle valeur écrite par PROC1.\
Il faut donc activer le mécanisme de SNOOP afin d'invalider les lignes de caches incohérentes.

### D4
En désactivant le mécanisme de Snoop, comme le processeur 0 a enregistré la première valeur de Snoop lue dans son cache, celui-ci attend qu'elle passe à 1 mais ce ne sera jamais le cas car une lecture sera suivie d'un HIT sur le cache, empêchant de voir la nouvelle valeur de *sync* écrite par le processeur 1.\
En l'occurence le processeur 1 ne pourra même pas modifier la variable *sync* car il attend que le processeur 0 la modifie, mais le même problème de cache est présent dans le processeur 1.\
Désactiver le mécanisme de Snoop met donc les deux programmes dans une boucle infinie.

### D5
Le coût matériel d'un mécanisme comme Snoop est qu'il doit constamment vérifier les lignes de caches, il doit donc être relié à chaque cache de chaque processeur.


## E - Problèmes de synchronisation liés au réordonnancement des instructions

### E1
Pour assurer l'odre d'exécution des instruction, on place l'appel *__sync_synchronize()* juste après l'écriture de BUF, val et sync.

### E2
Le code binaire a introduit l'instruction *sync* dans le code de producer() et de consumer().\
Le temps d'exécution ne change pas, le programme se termine au bout de 530 026 cycles.


## F - Synchronisation par FIFO logicielle

### F1
Le canal de communcation est une structure déclarée comme une variable globale car elle doit être accessible par tous les coeurs.

Les différents champs de la structure sont:

- buf : buffer contenant les données de la fifo
- ptw : pointeur d'écriture
- ptr : pointeur de lecture
- sts : status, nombre de données dans la fifo
- depth : profondeur, taille du buffer de donnée de la fifo
- lock : verrou informant si la fifo est libre ou en cours d'utilisation

### F2
Il est préférable d'utiliser un verrou à ticket afin d'assurer une allocation équitable de la fifo, pour éviter le phénomène de "famine" et faire en sorte que chaque processeur ait autant accès à la fifo qu'un autre processeur.\
On veut éviter que la fifo soit monopolisée par les processeurs ayant les tâches les plus rapides.

### F3
L'argument des deux fonction *lock_acquire* et *lock_release* est *plock* qui est une structure de verrou sous forme de ticket.

### F4
*lock_acquire* tire un numéro de ticket qui est libre avec la fonction *atomic_increment*, puis attend que celui-ci soit égal au ticket courant.

La fonction *atomic_increment* est écrite en assembleur afin d'effectuer une réservation LL/SC pour assurer la cohérence mémoire de la prise de ticket.

*atomic_increment* récupère ptr dans $10 et increment dans $22.\
Puis réserve l'espace 0(ptr) si c'est possible.\
Ajoute increment à $12 qui doit correspondre à l'ancienne valeur de 0(ptr) et enregistre le résultat dans $13.\
Fait un store conditionnal de la valeur incrémentée dans 0(ptr), puis recommence si ça n'a pas marché.\
Enfin, lorsque cela a marché, met l'ancienne valeur dans value et la retourne.\
La fonction renvoit donc l'ancienne valeur pointée par ptr et incrémente celle-ci de la valeur *increment*.

Dans le cas de *lock_acquire*, *atomic_increment* incrémente la valeur du prochain ticket libre de façon atomique afin d'assurer la cohérence mémoire et de gérer les accès concurrents à cette variable.

### F5
Pour libérer le verrou, *lock_release* incrémente la valeur du ticket courant.\
Cette fonction n'a pas besoin d'être écrite en assembleur car la cohérence est déjà assurée par le mécanisme de prise de verrou.\
En effet, il ne peut y avoir d'écriture concurrente sur cette variable car seule le programme ayant obtenu un verrou, dont la cohérence est assurée, peut libérer ce verrou.

### F6
Si une tâche ne peut effectuer son transfert parce-que la FIFO est pleine, elle doit impérativement libérer le verrou sous risque de provoquer un deadlock qui empêcherait tout autre programme de prendre le verrou de la fifo dont le lecteur.

### F7
fifo_write:
> fifo->buf[fifo->ptw] = *val;\
            fifo->ptw = (fifo->ptw + 1) % fifo->depth;\
            fifo->sts += 1;\
            lock_release((lock_t *) (&fifo->lock));\
            done = 1;

fifo_read:
>  *val = fifo->buf[fifo->ptr];\
            fifo->ptr = (fifo->ptr + 1) % fifo->depth;\
            fifo->sts -= 1;
            lock_release((lock_t*) (&fifo->lock));\
            done = 1;

### F8
| DEPTH   | 1    | 2    | 4    | 8    |
|:--------|:---: |:---: |:---: |:---: |
|Producer |611016|572782|526714|562928|
|Consumer |615322|565690|556412|586661|

On peut conclure que la profondeur de la fifo a une influence sur le nombre de cycles. Si elle est trop petite, celle-ci peut faire attendre le producteur ou le consommateur.

### F9

