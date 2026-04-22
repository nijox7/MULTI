# Compte-rendu TP9

## Notes

## C - Application producteur / consommateur

### C1
Question C1 : En analysant le code C des deux fonctions producer() et consumer() dans le fichier main_bipro.c, décrivez ce que vous pensez voir sur les deux terminaux TTY[0] et TTY[1].

Sur le terminal TTY[0] on devrait voir les messages:\
> transmitted value : 1     temporisation = 100

...
> transmitted value : 50    temporisation = 100

Sur le terminal TTY[1] on devrait voir les messages:\
> received value : 1      temporisation = 100

...
> received value : 50     temporisation = 100

On ne sait pas si le TTY[1] va afficher de 0 à 49 ou de 1 à 50 ou autre chose. Cela dépend de si le TTY[0] est plus rapide ou pas que le TTY[1].


Comme dans les TPs précédents, c'est le code de boot qui lance les deux tâches consumer et producer sur deux processeurs différents.


### C2
Question C2 : Complétez le code assembleur contenu dans le fichier reset.s pour que les tâches producer et consumer soient lancées sur les processeurs 0 et 1 respectivement.

