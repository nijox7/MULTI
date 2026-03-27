
#include "config.h"
#include "stdio.h"

#define NPIXEL 256
#define NLINE  256

/**
 *build function
 */
unsigned char build(unsigned int x, unsigned int y, unsigned int step) {
    if (((x >> step & 0x1) && !(y >> step & 0x1)) ||  // x(step) NOR y(step)
       (!(x >> step & 0x1) &&  (y >> step & 0x1))) {
        return 0xFF;
    }
    else {
        return 0;
    }
}


/**
 * main function
 */
__attribute__ ((constructor)) void main() {
    unsigned char buf[NPIXEL];
    int n = procid();
    int nprocs = NB_PROCS;

    // échiquier de 64+64=128
    // 1 case = 32*32 pixels
    // => 2^(17) = 131 072 pixels
    int line = 0;
    for (; line < NLINE; line += 1) {
    // parcourt chaque ligne de pixel
        if (line%nprocs == n){
            int pixel = 0;
            for (; pixel < NPIXEL; pixel += 1) { 
            // parcourt chaque pixel de la ligne
                buf[pixel] = build(pixel, line, 5);
                // détermine la couleur du pixel
            }
            if (fb_sync_write(NPIXEL*line, &buf, NPIXEL)) {
                tty_printf(" !!! wrong transfer to frame buffer for line %d\n", line);
            }
            else {
                tty_printf(" - building line %d\n", line);
            }
        }
    }

    tty_printf("\ncycles = %d\n", proctime());
    exit(); 
}

