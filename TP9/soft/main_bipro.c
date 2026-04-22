/********************************************************
 * File : main_bipro.c
 * Author : Alain Greiner
 * Date : 08/04/2010
 * Copyright : UPMC/LIP6
 ********************************************************
 * This file contains a very simple parallel, 
 * cooperative application.
 * - The producer task writes a sequence of integer 
 * values in a shared memory buffer BUF, after
 * displaying each value on its private TTY.
 * The parameter PRODUCER_DELAY can be used to 
 * adjust the producer data rate.  
 * - The consumer task reads those values in the
 * communication buffer, and displays the values on
 * its private TTY.
 * The parameter CONSUMER_DELAY can be used to 
 * adjust the consumer data rate.
*********************************************************/
#include "stdio.h"

#define NMAX 50

#define PRODUCER_DELAY 100
#define CONSUMER_DELAY 100

volatile int BUF = 0;


__attribute ((constructor)) void producer() {
    int tempo = PRODUCER_DELAY;
    int val;

    tty_printf("*** Starting task producer on processor %d ***\n\n", procid());

    for (int n = 0; n < NMAX; n += 1) { 
        for (int x = 0; x < tempo; x += 1) {
            asm volatile ("");
        }
        BUF = n;
        tty_printf("transmitted value : %d     temporisation = %d\n", n, tempo);
    }

    tty_printf("\n*** Completing producer at cycle %d ***\n", proctime());
    exit();

} // end producer()


__attribute ((constructor)) void consumer() {
    int val;
    int tempo = CONSUMER_DELAY;

    tty_printf("*** Starting task consumer on processor %d ***\n\n", procid());

    for (int n = 0; n < NMAX; n += 1) { 
        for (int x = 0; x < tempo; x += 1) {
            asm volatile ("");
        }
        val = BUF;
        tty_printf("received value : %d     temporisation = %d\n", val, tempo);
    }

    tty_printf("\n*** Completing consumer at cycle %d ***\n", proctime());
    exit();

} // end consumer()


