#ifndef PRINTK_H
#define PRINTK_H

#include <stdarg.h>
#include "font.h"

#define ZEROPAD 1
#define SIGN    2
#define PLUS    4
#define SPACE   8
#define LEFT    16
#define SPECIAL 32
#define SMALL   64

extern unsigned char ascii_char[256][16];

char buf[4096] = {0};

struct ScreenPosition
{
    int Xresolution;        // resolution
    int Yresolution;

    int XPosition;          // cursor x
    int YPosition;          // cursor y

    int XCharSize;          // char size
    int YCharSize;

    unsigned int *FP_addr;
    unsigned long FP_length;
} pos;

#endif