
#include "stdio.h"
#include "config.h"

#define NPIXEL 256
#define NLINE  256



__attribute__ ((constructor)) void main() {
    int n = procid();
    tty_printf("Start Main for proc %d\n", n);
    if (barrier_init(n, NB_PROCS) != 0) {
       	tty_printf("Error barrier_init\n");
	exit();
    }
    tty_printf("Barrier initialized\n");
    if (barrier_wait(n) != 0) {
	tty_printf("Error barrier_wait\n");
	exit();
    }
    tty_printf("End of programm");
    exit();
}
/*
    unsigned char BUF1[NPIXEL * NLINE];
    unsigned char BUF2[NPIXEL * NLINE];


    unsigned char* buf_build; // buffer pour construire l'image
    unsigned char* buf_print; // buffer pour afficher l'image


    // i0 build=buf1 print=buf2 construit 1
    // i1 build=buf2 print=buf1 construit 2 print 1
    // ..
    // i5 build=buf2 print=buf2             print 5

    barrier_init(n, NB_PROCS);

    for (int i = 0; i < 6; i++){
        tty_printf("--- i = %d ---\n", i);
	if (i%2 == 0) {
            buf_build = BUF1;
            buf_print = BUF2;
        }
        else{
            buf_build = BUF2;
            buf_print = BUF1;
        }

        if (i > 0 && (n == 0)){ // affichage
            if (fb_write(0, buf_print, NLINE * NPIXEL) != 0) {
                tty_printf("\n!!! error in fb_write syscall !!!\n");
                exit();
            }

        }

        if (i < 5){ // construction
            tty_printf("\n*** damier %d ***\n\n", i+1);
            for (int pixel = 0; pixel < NPIXEL; pixel += 1) {
                for (int line = 0 ; line < NLINE ; line += 1) {
                    if (line % NB_PROCS == n){
                        if (( (pixel>>(i+1) & 0x1) && !(line>>(i+1) & 0x1)) ||
                            (!(pixel>>(i+1) & 0x1) &&  (line>>(i+1) & 0x1))) {
                            buf_build[NPIXEL * line + pixel] = 0xFF;
                        }
                        else {
                            buf_build[NPIXEL * line + pixel] = 0x0;
                        }
                    }
                }
            }
            tty_printf(" - build   OK at cycle %d\n", proctime());
        }

        if (i > 0 && (n == 0)){ // seulement le processeur d'id 0
            if(fb_completed()) { // wait until fb_write() finished
                tty_printf("\n!!! error in fb_completed syscall !!!\n");
                exit();
            }
            tty_printf(" - display OK at cycle %d\n", proctime());
        }

        if (i < 5){
		tty_printf("On attend\n");
   		barrier_wait(n);
		tty_printf("Fin de l'attente\n");
	}
    }

    tty_printf("\nFin du programme au cycle = %d\n\n", proctime());
    exit();
} // end main
*/
