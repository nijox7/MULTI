# Compte-rendu TP9

## Notes

## C - Application producteur / consommateur

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