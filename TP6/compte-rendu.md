# Compte-rendu TP6

## C - Composants périphériques

Pibusslcu -> 32 lignes d'interruptions IN
          -> 1 ligne OUT (1 sortie / processeur)

IT_Vector -> index de l'interruption en priorité
          -> peut masqué interruption avec mask 32 bits (1 mask / processeur)

Timer     -> plusieurs timers
          -> 1 ligne interruption / timer
          -> 1 ISR pour tous les timers?

TTY       -> 1 ligne interruption / TTY
          -> ISR: _ist_tty_get

mécanisme de scrutation = mécanisme d'examen en continu de quelque chose


PibusMultiTTY:
- nb tty
- automate, registre d'état, fonction de transition
- mask 16 clavier
- mask 16 affichage
- keyboard character
- ports Pibus + ports Irq
- m_fsm_str -> tableau des noms des états de l'automate (idle, display, status, keyboard..)

PibusMultiTimer:
- nb timer
- automate comme tty
- Mêmes ports que tty
- registres counter, running, period

PibusIcu:
- mask for 8 outputs
- number of inputs/outputs IRQs = nirq/nproc
- automate
- Mêmes ports pibus

eret -> permet de sortir du mode kernel

Pour le cache " 4 fois associatifs ayant une capacités de 4 Koctets et des lignes de cache de 32 octets (8 mots)"
On prend 32 ensembles car 4 * 32 * 

### C1
Le composant PibusMultiTimer est configurable en logiciel, il est donc une cible sur le bus pour permettre de le configurer en accèdant à son registre de mask.

L'argument 'ntimer' de ce composant permet de définir le nombre de timers programmables du composant. Cela va également définir le nombre de signaux d'interruptions en sortie.

Les registres adressables de ce composant sont:\

- *r_value*:\
Adresse: SEG_TIM_BASE + n_timer*0x10.\
Permet de définir ou de lire la valeur du timer.

- *r_running*:\
Adresse: SEG_TIM_BASE + 0x4 + n_timer*0x10.\
Permet d'activer (1) ou de désactiver (0) l'incrémentation du timer.

- *r_period*: Adresse:\
SEG_TIM_BASE + 0x8 + n_timer*0x10.\
Permet de définir la période d'incrémentation du timer en npmbre de cycles.

- *r_irq*:\
Adresse: SEG_TIM_BASE + 0xC + n_timer*0x10.\
Permet d'activer (1) ou désactiver (0) les interruptions.

### C2
Le composant PibusIcus est une cible sur le bus car il permet de programmer les interruptions. Ce sont donc les processeurs qui vont faire des transactions sur le bus pour le programmer.

L'argument *nirq* du contructeur permet de définir le nombre d'interruptions que l'on veut gérer en entrée de l'ICU.

L'argument *nproc* définit le nombre de processeur connectés à l'ICU, et donc le nombre de sorties de l'ICU.

Un logiciel peut aiguiller les interruptions de l'ICU à l'aide d'un mask pour chacun des processeurs. Ces masks permettent aux processeurs de choisir les interruptions qui les intéressent.

Les registres adressables de ce composant sont:\
- *r_int*:\ 
Adresse: SEG_ICU_BASE + 0x0 + n_proc*0x20\
Permet de lire le status des lignes d'interruptions.

- *r_mask*:\
Adresse: SEG_ICU_BASE + 0x4 + n_proc*0x20\
Permet de lire le mask des IRQ associé au processeur.

- *icu_set*:\
Adresse: SEG_ICU_BASE + 0x8 + n_proc*0x20\
Permet d'écrire les bits du mask IRQ.

- *icu_clear*:\
Adresse: SEG_ICU_BASE + 0xC + n_proc*0x20\
Permet de mettre à 0 les bits du mask IRQ.

- *icu_highest*:\
Adresse: SEG_ICU_BASE + 0x10 + n_proc*0x20\
Permet de lire le numéro de la ligne d'IRQ de priorité maximale.


### C3
L'adresse associée au composant PibusIcu doit être alignée sur 32*8 octets car
<!--TODO-->

### C4
Pour relier les 4 lignes d'interruptions, les ports IRQ_IN du contrôleur ICU sont connecté à des signaux internes qui sont eux-mêmes connecté aux composants PibusMultiTimer et PibusMultiTty.


## D - Lancement des tâches

### D1
<!-- TODO Détailler?? -->

### D2
L'adresse de main_prime() est 0x01000000.\
L'adresse de main_pgcd() est 0x01000004.

### D3
