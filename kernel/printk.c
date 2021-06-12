#include "printk.h"
#include <stdarg.h>
#include "lib.h"
#include "linkage.h"

#define do_div(n, base)({ \
    int __res; \
    __asm__("divq %%rcx":"=a" (n),"=d" (__res):"0" (n),"1" (0),"c" (base)); \
    __res; \
})

int color_printk(unsigned int fr_color, unsigned int bk_color, unsigned char *fmt, ...)
{
    int i = 0;
    int line = 0;
    int count = 0;      // used to track the character in the buf one by one

    va_list args;
    va_start(args, fmt);
    i = vsprintf(buf, fmt, args);
    va_end(args);

    // print each character one by one
    for (count = 0; count < i || line; count++){

        if (line > 0){
            goto Label_tab;
            count--;
        }
        
        if ((unsigned char)*(buf+count) == '\n'){
            pos.YPosition++;
            pos.XPosition = 0;
        }
        else if ((unsigned char)*(buf+count) == '\b'){
            pos.XPosition--;
            if (pos.XPosition < 0){
                pos.YPosition--;
                pos.XPosition = pos.Xresolution / pos.XCharSize - 1;

                if (pos.YPosition < 0){
                    pos.YPosition = pos.Yresolution / pos.YCharSize - 1;
                }
            }

            putChar(pos.FP_addr, pos.Xresolution, pos.XPosition * pos.XCharSize, pos.YPosition * pos.YCharSize, fr_color, bk_color, ' ');
        }
        else if ((unsigned char)*(buf+count) == '\t'){
            line = (pos.XPosition + 8) & (~(7)) - pos.XPosition;

        Label_tab:
            line--;

            putChar(pos.FP_addr, pos.Xresolution, pos.XPosition * pos.XCharSize, pos.YPosition * pos.YCharSize, fr_color, bk_color, ' ');
            pos.XPosition++;
        }
        else{
            putChar(pos.FP_addr, pos.Xresolution, pos.XPosition * pos.XCharSize, pos.YPosition * pos.YCharSize, fr_color, bk_color, (unsigned char)*(buf+count));
            pos.XPosition++;
        }

        // check the Xposition and Yposition for boundary
        if (pos.XPosition >= pos.Xresolution / pos.XCharSize){
            pos.XPosition = 0;
            pos.YPosition++;
        }

        if (pos.YPosition >= pos.Yresolution / pos.YCharSize){
            pos.YPosition = 0;
        }
    }

    return i;
}

int skip_atoi(const char **fmt)
{
    int i = 0;
    if (is_digit(**fmt)){
        i = i*10 + *(*(fmt)++) - '0';
    }

    return i;
}

int vsprintf(char *buf, const char *fmt, va_list args)
{
    char *str, *s;                // str is the buffer
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
                        while (--fields_width > 0){
                            *str++ = ' ';
                        }
                    }
                    *str++ = (unsigned char)va_arg(args, int);
                    while(--fields_width > 0){
                        *str++ = ' ';
                    }

                    break;

                case 's':
                    s = va_arg(args, char*);
                    if (!s){
                        *s = '\0';
                    }
                    len = strlen(s);

                    if (precision < 0){
                        precision = len;
                    }
                    else if (len > precision){
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

                // octal
                case 'o':
                    if (qualifier == 'l'){
                        str = number(str, va_arg(args, unsigned long), 8, fields_width, precision, flags);
                    }
                    else{
                        str = number(str, va_arg(args, unsigned int), 8, fields_width, precision, flags);
                    }

                    break;

                // address
                case 'p':
                    if (fields_width == -1){
                        fields_width = 2 * sizeof(void *);
                        flags |= ZEROPAD;
                    }

                    str = number(str, va_arg(args, unsigned long), 16, fields_width, precision, flags);

                    break;

                case 'x':
                    flags |= SMALL;
                case 'X':
                    if (qualifier == 'l'){
                        str = number(str, va_arg(args, unsigned long), 16, fields_width, precision, flags);
                    }
                    else{
                        str = number(str, va_arg(args, unsigned int), 16, fields_width, precision, flags);
                    }

                    break;

                case 'd':
                case 'i':
                    flags |= SIGN;
                case 'u':
                    if (qualifier == 'l'){
                        str = number(str, va_arg(args, unsigned long), 10, fields_width, precision, flags);
                    }
                    else{
                        str = number(str, va_arg(args, unsigned int), 10, fields_width, precision, flags);
                    }

                    break;

                case 'n':
                    if (qualifier == 'l'){
                        long *ip = va_arg(args, long *);
                        *(ip) = (str - buf);
                    }
                    else{
                        int *ip = va_arg(args, int *);
                        *(ip) = (str - buf);
                    }

                    break;

                case '%':
                    *str++ = '%';
                    break;

                default:
                    *str++ = '%';
                    if (*fmt){
                        *str++ = *fmt;
                    }
                    else{
                        fmt--;
                    }

                    break;
            }

    }

    *str = '\0';
    return str-buf;
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

char *number(char *str, long num, int base, int field_width, int precision, int flags)
{
    char c;
    char sign;
    char tmp[50];

    int i;

    const char *digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    if (flags & SMALL){
        digits = "0123456789abcdefghijklmnopqrstuvwxyz";
    }

    if (flags & LEFT){
        flags &= ~ZEROPAD;
    }

    if (base < 2 || base > 36){
        return 0;
    }

    c = (flags &= ZEROPAD) ? '0' : ' ';
    sign = 0;
    if (flags & SIGN && num < 0){
        sign = '-';
        num = -num;
    }
    else{
        sign = flags & PLUS ? '+' : (flags & SPACE ? ' ' : 0);
    }

    if (sign){
        field_width--;
    }

    if (flags & SPECIAL){
        if (base == 16){
            field_width -= 2;
        }
        else if (base == 8){
            field_width--;
        }
    }


    i = 0;

    if (num == 0){
        tmp[i++] = '0';
    }
    else{
        while (num){
            tmp[i++] = digits[do_div(num,base)];
        }
    }

    if (i > precision){
        precision = i;
    }

    field_width -= precision;

    if (!(flags & (ZEROPAD + LEFT))){
        while (field_width-- > 0){
            *str++ = ' ';
        }
    }

    if (sign){
        *str++ = sign;
    }

    if (flags & SPECIAL){
        if (base == 8){
            *str++ = '0';
        }
        else if (base == 16){
            *str++ = '0';
            *str++ = digits[33];
        }
    }

    if (!(flags & LEFT)){
        while (field_width-- > 0){
            *str++ = c;
        }
    }

    while (i < precision--){
        *str++ = '0';
    }

    while (i-- > 0){
        *str++ = tmp[i];
    }

    while (field_width-- > 0){
        *str++ = ' ';
    }

    return str;
}