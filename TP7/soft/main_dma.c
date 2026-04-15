
#include "stdio.h"

#define NPIXEL 256
#define NLINE  256

__attribute__ ((constructor)) void main() {
    unsigned char BUF[NPIXEL * NLINE];

    for (int step = 1; step < 6; step += 1) {
        tty_printf("\n*** damier %d ***\n\n", step);

        for (int pixel = 0; pixel < NPIXEL; pixel += 1) { 
            for (int line = 0 ; line < NLINE ; line += 1) {
                if (( (pixel>>step & 0x1) && !(line>>step & 0x1)) || 
                    (!(pixel>>step & 0x1) &&  (line>>step & 0x1))) {
                    BUF[NPIXEL * line + pixel] = 0xFF;
                }
                else {
                    BUF[NPIXEL * line + pixel] = 0x0;
                }
            }
        }

        tty_printf(" - build   OK at cycle %d\n", proctime());

        if (fb_write(0, BUF, NLINE * NPIXEL) != 0) {
            tty_printf("\n!!! error in fb_syn_write syscall !!!\n"); 
            exit();
        }
	fb_completed(); // wait until fb_write() finished

        tty_printf(" - display OK at cycle %d\n", proctime());

    }
    tty_printf("\nFin du programme au cycle = %d\n\n", proctime());
    exit(); 
} // end main

