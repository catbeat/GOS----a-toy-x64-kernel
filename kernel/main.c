#include "lib.h"
#include "printk.h"

void Start_kernel(void)
{
    int *addr = (int *) 0xffff800000a00000;

    int i;

    pos.Xresolution = 1440;
    pos.Yresolution = 900;
    
    pos.XPosition = 0;
    pos.YPosition = 0;

    pos.XCharSize = 8;
    pos.YCharSize = 16;
    pos.FP_addr = addr;
    pos.FP_length = (pos.Xresolution * pos.Yresolution * 4);

    for (i = 0; i < 1440*20; ++i){
        *(((char *)addr) + 0) = (char) 0x00;
        *(((char *)addr) + 1) = (char) 0x00;
        *(((char *)addr) + 2) = (char) 0xff;
        *(((char *)addr) + 3) = (char) 0x00;

        addr+= 1;
    }

    for (i = 0; i < 1440*20; ++i){
        *(((char *)addr) + 0) = (char) 0x00;
        *(((char *)addr) + 1) = (char) 0xff;
        *(((char *)addr) + 2) = (char) 0x00;
        *(((char *)addr) + 3) = (char) 0x00;

        addr+= 1;
    }

    for (i = 0; i < 1440*20; ++i){
        *(((char *)addr) + 0) = (char) 0xff;
        *(((char *)addr) + 1) = (char) 0x00;
        *(((char *)addr) + 2) = (char) 0x00;
        *(((char *)addr) + 3) = (char) 0x00;

        addr+= 1;
    }

    for (i = 0; i < 1440*20; ++i){
        *(((char *)addr) + 0) = (char) 0xff;
        *(((char *)addr) + 1) = (char) 0xff;
        *(((char *)addr) + 2) = (char) 0xff;
        *(((char *)addr) + 3) = (char) 0x00;

        addr+= 1;
    }

    color_printk(YELLOW, BLACK, "Hello world\n");
    while(1)
        ;
}