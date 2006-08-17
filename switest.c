#include "armsim.h"

#include <termios.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <errno.h>
#include <assert.h>

#ifndef TCGETS
#define TCGETS 0x5401
#endif

int doIoctl()
{
   int a = 0x12345678;
   struct termios foo;
   int b = 0x87654321;
   memset(&foo, 0xa5, sizeof(foo));
   foo.c_iflag = 0x5a5a5a5a;
   printf("size is %d, &foo = %x, offset of c_ospeed=%d\n",
          sizeof(foo), &foo, (long)&foo.c_ospeed - (long)&foo);
   printf("before: a,b=%x,%x %x %x %x %x %d [%u..%u], %d %d\n", a, b,
          foo.c_iflag, foo.c_oflag, foo.c_cflag, foo.c_lflag, foo.c_line,
          (unsigned)foo.c_cc[0], (unsigned)foo.c_cc[sizeof(foo.c_cc)-1],
          foo.c_ispeed, foo.c_ospeed);
   int rc = ioctl(0, TCGETS, &foo);
   assert(a == 0x12345678 && b == 0x87654321 && foo.c_iflag != 0x5a5a5a5a);
   printf("rc=%d, a,b=%x,%x %x %x %x %x %d [%u..%u], %d %d\n", rc, a, b,
          foo.c_iflag, foo.c_oflag, foo.c_cflag, foo.c_lflag, foo.c_line,
          (unsigned)foo.c_cc[0], (unsigned)foo.c_cc[sizeof(foo.c_cc)-1],
          foo.c_ispeed, foo.c_ospeed);

   return 0;
}

int doMalloc()
{
   int i;
   for (i=0; i<5; i++) {
       char *m = malloc(100);
       printf("#%d 100bytes at %x, errno=%d\n", i, m, errno);
       assert(errno == ENOMEM || m != NULL);
   }
}

int main()
{
   doMalloc();
   doIoctl();
   return 0;
}

