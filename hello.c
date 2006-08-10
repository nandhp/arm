#include <armsim.h>

int main() {
  int i;
  /* aprintf("%u\n",1-2); */
  aprintf("Testing aprintf now.\naprintf supports: d, i, u, x, X, o, b, s, c\n\n");
  aprintf("Testing %%d:\t");
  aprintf("%s=%d\n","1+2",1+2);
  /*#if 0*/
  aprintf("Testing %%c:\t");
  aprintf("%c%c%c\n",'a','b','c');
  aprintf("Testing <=0:\t");
  /*#endif*/
  aprintf("1-1=%u, 1-2u=%u, 1-3d=%d\n",1-1,1-2,1-3);
  aprintf("1-1=0, 1-2=%d\n",1-2);
  aprintf("Testing %%dxX:\t");
  int a, b; a = 511; b = 65535;
  aprintf("  %d+ %d=  %d\n",a,b,a+b);
  aprintf("\t\t0x%x+0x%x=0x%x\n",a,b,a+b);
  aprintf("\t\t0x%X+0x%X=0x%X\n\n",a,b,a+b);
  aprintf("Displaying ritual pointless message:\n\t");
  aprintf("Hello, world!\n\n");
  aprintf("Counting in multiple bases:\n");
  for ( i=0;i<=16;i++ ) {
    aprintf("%d\t%x\t%o\t%b\n",i,i,i,i);
  }
  aprintf("\n\nProgram complete.\n");
  return 0;
}
