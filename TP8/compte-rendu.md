# Compte-rendu TP8

## Notes
images.raw:
21 * 128*128 * 256 = 21 * (2^7)*(2^7) * (2^8)
                   = 21 * (2^22)
        (environ)  = 21 * 4 000 000 = 84 000 000

Disque -> tête de lecture -> ralentit les accès

## B - Contrôleur de disque

### B1
- L'argument *block_size* est la taille en octets d'un bloc sur le disque.

- L'argument *latency* est le nombre de cycles d'attente pour effectuer un accès mémoire sur le disque.

### B2
On a $128 \times 128$ pixels de $1$ octet dans une image. Donc une image fait $2^7 \times 2^7 \approx 16 000$ octets environ.\
Une image occupe donc $(2^7 \times 2^7) / 2^9 = 2^5 = 32$ blocs.


### B3
Les registres adressable du Block_Device sont:

- <b>BLOCK_DEVICE_BUFFER</b>: Une écriture sur ce registre permet de définir l'adresse du buffer utilisateur mais est ignorée si le Block_Device n'est pas en IDLE.

- <b>BLOCK_DEVICE_COUNT</b>: Une écriture sur ce registre permet de définir le nombre de blocs à traiter lors du transfert. Elle est ignorée si le Block_Device n'est pas en IDLE.

- <b>BLOCK_DEVICE_LBA </b>: Une écriture sur ce registre permet de définir l'adresse du premier bloc du transfert sur le disque. Elle est ignorée si le Block_Device n'est pas en IDLE.

- <b>BLOCK_DEVICE_OP</b>: Un accès en écriture sur ce registre lance un transfert du type que l'on y écrit. Si le Block_Device n'est pas en IDLE, l'écriture est ignorée.

- <b>BLOCK_DEVICE_STATUS</b>: Un accès en lecture sur ce registre provoque le reset de l'automate master à l'état Idle sir le Block_Device est dans l'un des états suivants: READ_ERROR, READ_SUCCESS, WRITE_ERROR, WRITE_SUCCESS.

- <b>BLOCK_DEVICE_IRQ_ENABLE</b>: Si on écrit 1 da      ns ce registre, on active les IRQ. Si on écrit 0 on les désactive.

- <b>BLOCK_DEVICE_SIZE</b>: Une lecture de ce registre nous donne le nombre de blocs adressables sur le disque.

- <b>BLOCK_DEVICE_BLOCK_SIZE</b>: On peut lire la taille d'un bloc du disque sur ce registre.


### B4
Les valeurs de l'état interne du contrôleur de disque qui peuvent être lues par le logiciel sont:

- <b>BLOCK_DEVICE_IDLE</b>: Attend un nouveau transfert.

- <b>BLOCK_DEVICE_BUSY</b>: Est occupé par un transfert.

- <b>BLOCK_DEVICE_READ_SUCCESS</b>: A réussit un tranfert de lecture et attend l'acquittement de l'IRQ par le logiciel.

- <b>BLOCK_DEVICE_WRITE_SUCCESS</b>: A réussit un tranfert d'écriture et attend l'acquittement de l'IRQ par le logiciel.

- <b>BLOCK_DEVICE_READ_ERROR</b>: Le transfert de lecture a échoué, et le contrôleur de disque attend que l'IRQ soit acquittée par le logiciel.

- <b>BLOCK_DEVICE_WRITE_ERROR</b>: Le transfert de lecture a échoué, et le contrôleur de disque attend que l'IRQ soit acquittée par le logiciel.


## C - Architecture matérielle

On définit le timeout du composant PibusSegBcu à 1 000 000.

### C1
L'utilisation du composant PibusBlockDevice impose de changer la valeur du timeout du composant PibusSegBcu car une transaction sur le bus avec le PibusBlockDevice prend beaucoup plus que 100 cycles.\
Un accès à la mémoire du disque est beaucoup plus lent qu'un transfert de donnée depuis la RAM.\
Le prix d'un accès sur le disque pouvant aller jusqu'a plusieurs millions de cycles pour un disque magnétique, on met le timeout à 10 000 000 de cycles.

### C2
- Le segment IOC a pour adresse de base 0x92000000 et fait 32 octets.

- Le segment ICU a une longueur de 32*nprocs octets.

- Le segment TTY a une logueur de 16*nprocs octets.

- Le segment TIMER a une logueur de 16*nprocs octets.

### C3
- Maitres: DMA, IOC, nbprocs * PROC. On a donc 2 composants maitres sans compter les processeurs.

- Cibles: DMA, IOC, Timer, TTY, ICU, FBF, RAM, ROM. On a donc 8 composants cibles.


### C4
Le composant ICU reçoit comme lignes d'interrutpions: 1 pour DMA, 1 pour IOC, 1 par processeur pour TIMER et 1 par processeur pour TTY.\
Le composant ICU reçoit un total de 2 + 2*nbprocs lignes d'interruptions entrantes.\

Le nombre de lignes d'interruptions sortantes est égal au nombre de coeurs.\

Les IRQs provenant des périphériques sont connectés au comosant ICU à l'aide des signaux *signal_irq_dma*, *signal_irq_ioc*, *signal_irq_tim* et *signal_irq_tty_get*.


## D - Code de boot

### D1
Le pointeur de pile dépend du numéro de processeur car chaque processeur possède sa propre pile afin d'assurer la cohérence mémoire au sein d'un même programme.

### D2
Afin de router les lignes d'interruptions du composant ICU vers les différents processeurs, on configure un mask pour chaque processeur permettant de filtrer les interruptions qui intéresse chaque processeur.

### D3
- Proc 0: 0b 0000 0000 1111
- Proc 1: 0b 0000 0011 0000
- Proc 2: 0b 0000 1100 0000
- Proc 3: 0b 0011 0000 0000
