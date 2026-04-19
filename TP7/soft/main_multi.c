
#include "stdio.h"
#include "config.h"

#define NPIXEL 256
#define NLINE  256

__attribute__ ((constructor)) void main() {

    unsigned char BUF1[NPIXEL * NLINE];
    unsigned char BUF2[NPIXEL * NLINE];
    int n = procid();

    unsigned char* buf_build; // buffer pour construire l'image
    unsigned char* buf_print; // buffer pour afficher l'image


    // i0 build=buf1 print=buf2 construit 1
    // i1 build=buf2 print=buf1 construit 2 print 1
    // ..
    // i5 build=buf2 print=buf2             print 5

    for (int i = 0; i < 6; i++){
        if (i%2 == 0) {
            buf_build = BUF1;
            buf_print = BUF2;
        }
        else{
            buf_build = BUF2;
            buf_print = BUF1;
        }
/*
        if (i > 0 && n == 0){ // affichage
            if (fb_write(0, buf_print, NLINE * NPIXEL) != 0) {
                tty_printf("\n!!! error in fb_write syscall !!!\n"); 
                exit();
            }

        }
*/
        if (i < 5){ // construction
            barrier_init(4, n); // barière pour 4 processeurs, initialisation pour le proc n

            tty_printf("\n*** damier %d ***\n\n", i+1);
            for (int pixel = 0; pixel < NPIXEL; pixel += 1) { 
                for (int line = 0 ; line < NLINE ; line += 1) {
                    if (line % NB_PROCS == n){
                        if (( (pixel>>(i+1) & 0x1) && !(line>>(i+1) & 0x1)) || 
                            (!(pixel>>(i+1) & 0x1) &&  (line>>(i+1) & 0x1))) {
//                            buf_build[NPIXEL * line + pixel] = 0xFF;
                        }
                        else {
//                            buf_build[NPIXEL * line + pixel] = 0x0;
                        }
                    }
                }
            }
            tty_printf(" - build   OK at cycle %d\n", proctime());
        }
/*
        if (i > 0 && n == 0){ // seulement le processeur d'id 0
            if(fb_completed()) { // wait until fb_write() finished
                tty_printf("\n!!! error in fb_completed syscall !!!\n");
                exit();
            }
            tty_printf(" - display OK at cycle %d\n", proctime());
        }

        if (i < 5) barrier_wait(n);
*/
    }

    tty_printf("\nFin du programme au cycle = %d\n\n", proctime());
    exit();
} // end main
