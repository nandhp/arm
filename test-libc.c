#include "armsim.h"
#include <string.h>
#include <stdlib.h>

int main() {
  char *a = "Apples are like oranges";
  char *b = "this is a test string";
  char *c = " Zebras now available in full 16-bit color";
  char *d = "";
  char t[128] = "";
  char *f;
  int rands[10];
  int randsize = sizeof(rands)/sizeof(rands[0]);
  int x;

  srand(12345);
  for ( x = 0; x < randsize; x++ ) {
    rands[x] = rand();
  }
  srand(12345);
  for ( x = 0; x < randsize; x++ ) {
    assert(rand() == rands[x]);
  }
  for ( x = 0; x < (randsize-1); x++ ) {
    if ( rands[x] != rands[x+1] ) break;
    if ( x+1 == randsize ) assert(0);
  }

  assert(x >= 0 && x < RAND_MAX);
  assert(strlen(a) == 23);
  assert(strlen(b) == 21);
  assert(strlen(c) == 42);
  assert(strlen(d) == 0);

  assert(strcmp(a,a) == 0);
  assert(strcmp(b,b) == 0);
  assert(strcmp(c,c) == 0);
  assert(strcmp(d,d) == 0);

  assert(strcmp(a,b) <  0);
  assert(strcmp(b,a)  > 0);

  assert(strcmp(a,c)  > 0);
  assert(strcmp(c,a) <  0);

  assert(strcmp(b,c)  > 0);
  assert(strcmp(c,b) <  0);

  assert(strcmp(d,a) <  0);
  assert(strcmp(d,b) <  0);
  assert(strcmp(d,c) <  0);
  assert(strcmp(a,d)  > 0);
  assert(strcmp(b,d)  > 0);
  assert(strcmp(c,d)  > 0);

  assert(isupper('A') && !isupper('a') && !isupper(' '));
  assert(atoi("") == 0);
  assert(atoi("0") == 0);
  assert(atoi("1982") == 1982);
  
  sprintf(t,"Testing a thingy, %d",12);
  assert(strcmp(t,"Testing a thingy, 12") == 0);
  sprintf(t,"");
  assert(strcmp(t,"") == 0);
  sprintf(t,"String %sing%%","Process");
  assert(strcmp(t,"String Processing%") == 0);
  assert((f = strchr(t,'P')) != NULL);
  assert(strcmp(f,"Processing%") == 0);

  assert(sqrt(9) == 3);
  assert(pow(2,3) == 8);
  printf("Sleeping 1...\n");
  assert(sleep(1) == 0);
  printf("ok\n");
  return 0;
}
