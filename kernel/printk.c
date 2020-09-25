#include "printk.h"
#include <stdarg.h>
#include "lib.h"
#include

int color_printk(unsigned int fr_color, unsigned int bk_color, unsigned char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);


}

int skip_atoi(const char **fmt)
{
    int i = 0;
    if (is_digit(*fmt)){
        i = i*10 + *(*(fmt)++) - '0';
    }

    return i;
}

int vsprintf(char *buf, const char *fmt, va_list args)
{
    char *str = buf, *s;                // str is the buffer
    int flags;
    int fields_width;
    int precision;
    int qualifier;

    int len;

    for (str = buf; *fmt ; fmt++){
        if ((*fmt) != '%'){
            *(str++) = *fmt;
            continue;
        }

        // record the format flag
        flags = 0;

        repeat:                 
            fmt++;
            switch(*fmt)
            {
                case '-':
                    flags |= LEFT;
                    goto repeat; 
                
                case '+':
                    flags |= PLUS;
                    goto repeat;

                case ' ':
                    flags |= SPACE;
                    goto repeat;

                case '#':
                    flags |= SPECIAL;
                    goto repeat;

                case '0':
                    flags |= ZEROPAD;
                    goto repeat;
            }

            fields_width = -1;
            if (is_digit(*fmt)){
                fields_width = skip_atoi(&fmt);
            }
            else if (*fmt == '*'){
                fmt++;
                fields_width = va_arg(args, int);
                if (fields_width < 0){
                    fields_width = -fields_width;
                    flags |= LEFT;
                }
            }

            precision = -1;
            if (*fmt == '.'){
                fmt++;
                if (is_digit(*fmt)){
                    precision = skip_atoi(&fmt);
                }
                else if (*fmt == '*'){
                    fmt++;
                    precision = va_arg(args, int);
                }

                if (precision < 0){
                    precision = 0;
                }
            }

            qualifier = -1;
            if (*fmt == 'h' | *fmt == 'l' | *fmt == 'L' | *fmt == 'Z'){
                qualifier = *fmt;
                fmt++;
            }

            switch(*fmt)
            {
                case 'c':
                    // align to right, so filled with space
                    if (!(flags & LEFT)){
                        while (--precision > 0){
                            *str++ = ' ';
                        }
                    }
                    *str++ = (unsigned char)va_arg(args, int);
                    while(--precision > 0){
                        *str++ = ' ';
                    }

                    break;

                case 's':
                    s = va_arg(args, char*);
                    if (!s){
                        *s = '\0';
                    }
                    len = strlen(s);

                    if (len > precision){
                        len = precision;
                    }

                    if (!(flags & LEFT)){
                        while(fields_width-- > len){
                            *str++ = ' ';
                        }
                    }
                    for (int i = 0; i < len; ++i){
                        *str++ = *s++;
                    }

                    while(fields_width-- > len){
                        *str++ = ' ';
                    }

                    break;

                case 'f':
                    

            }

    }
}

void putChar(unsigned int *fb, int XSize, int x, int y, unsigned int fr_color, unsigned int bk_color, unsigned char font)
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