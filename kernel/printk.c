#include "printk.h"
#include <stdarg.h>
#include "lib.h"

int color_printk(unsigned int fr_color, unsigned int bk_color, unsigned char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);


}

void putChar(unsigned int *fb, int XSize, int x, int y, unsigned int fr_color, unsigned bk_color, unsigned char font)
{
    int i = 0, j = 0;
    int testval = 0x100;
    unsigned int *addr = NULL;
    unsigned char *fontp = NULL;
    fontp = ascii_char[font];

    for (; i < 16; ++i){
        addr = fb + XSize*(y + i) + x;
        testval = 0x100;

        for (j = 0; j < 8; ++j){
            testval >>= 1;
            if (*fontp & testval){
                *addr = fr_color;
            }
            else{
                *addr = bk_color;
            }

            addr++;
        }
        fontp++;
    }
}