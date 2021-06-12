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

#define is_digit(c) ((c) >= '0' && (c) <= '9')

#define WHITE 	0x00ffffff		
#define BLACK 	0x00000000		
#define RED	    0x00ff0000		
#define ORANGE	0x00ff8000		
#define YELLOW	0x00ffff00		
#define GREEN	0x0000ff00		
#define BLUE	0x000000ff		
#define INDIGO	0x0000ffff		
#define PURPLE	0x008000ff		

int skip_atoi(const char **fmt);
int vsprintf(char *buf, const char *fmt, va_list args);
void putChar(unsigned int *fb, int XSize, int x, int y, unsigned int fr_color, unsigned int bk_color, unsigned char font);
char *number(char *str, long num, int base, int field_width, int precision, int flags);
int color_printk(unsigned int fr_color, unsigned int bk_color, unsigned char *fmt, ...);

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