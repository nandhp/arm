/** @file armsim.h
 *
 * Perl ARM Simulator
 * C Helper Functions
 *
 * Copyright (c) 2006 nandhp. Licensed under the GNU GPL.
 * http://www.gnu.org/copyleft/gpl.html
 */

#include <stdarg.h>		/* For aprintf() */

#ifdef NOARMSIM			/* Includes for real systems */
#include <stdio.h>
#include <assert.h>
#endif

#ifndef NOARMSIM		/* Redefinitions for ARM Simulator */
#define printf aprintf
#define assert(x) if (!(x)) asm("\n swi #18" : : );
#endif

/** Output one character using ARM Simulator SWI or STDIO */
void printc(char c) {
#ifdef NOARMSIM
  printf("%c",c);
#else
  asm(" stmdb sp!, {r0}\n mov r0, %0\n swi #2\n ldmia sp!, {r0}"
      : 
      : "r"(c));
#endif
}

/** Reimplementation of printf(3) using printc() */
void aprintf(const char *format,...) {
  va_list ap;
  va_start(ap, format);
  while ( *format ) {
    if ( *format == '%' ) {
      int width = 0;
      int padmode = 0;
      format++;

      /* Format width */
      if ( *format == '0' ) {
	padmode = 1;
	format++;
      }
      while ( *format >= '0' && *format <= '9' ) {
	width *= 10;
	width += *format-'0';
	format++;
      }

      if ( *format == '%' ) printc(*format);
      else if (  *format == 'b' ) {
	unsigned int x = va_arg(ap, unsigned int);
	char temp[32];
	int tix = 0;
	int r = 0;
	memset(temp,'0',32);
	if ( x == 0 ) tix++;
	while ( x > 0 ) {
	  int c = x & 1;
	  if ( c ) temp[tix] = '1';
	  x >>= 1;
	  tix++;
	}
	for ( ;width > tix; width-- ) printc(padmode?'0':' ');
	for ( tix--;tix >= 0;tix-- ) {
	  printc(temp[tix]);
	}
      }
      else if ( *format == 'd' || *format == 'u' || *format == 'x' ||
		*format == 'X' || *format == 'b' || *format == 'o' ||
		*format == 'i' ) {
	int use_signed = ((*format == 'd' || *format == 'i') ? 1 : 0);
	int base_number = 10;
	unsigned int x;
	if ( *format == 'x' || *format == 'X' ) base_number = 16;
	if ( *format == 'b' ) base_number = 2;
	if ( *format == 'o' ) base_number = 8;

	if ( use_signed ) { /* Signed/Unsigned */
	  signed int y = va_arg(ap, signed int);
	  if ( y < 0 ) { printc('-'); x = (unsigned int)(-y); }
	  else { x = (unsigned int)y; }
	}
	else x = va_arg(ap, unsigned int);

	char temp[32];
	int tix = 0;
	int fv = 0;
	int r = 0;
	memset(temp,'0',32);
	if ( x == 0 ) tix++;

asm("\nyour_friendly_neighbourhood_spiderman:");
	while ( x > 0 ) {
	  fv = x % base_number; x-= fv;
	  assert(fv >= 0 && fv < base_number);

	  temp[tix] = fv+'0';
	  if ( fv > 9 ) temp[tix] = fv-10+(*format == 'X' ? 'A' : 'a');
	  if ( temp[tix] > 'F' && temp[tix] <= 'Z' ) printc('!');
	  if ( temp[tix] > 'f' ) printc('?');
	  x=x/base_number;
	  fv=0;
	  tix++;
	}
	for ( ;width > tix; width-- ) printc(padmode?'0':' ');
	for ( tix--;tix >= 0;tix-- ) {
	  printc(temp[tix]);
	}
      }
      else if ( *format == 'c' ) {
	unsigned int x = va_arg(ap, unsigned int);
	printc(x);
      }
      else if ( *format == 's' ) {
	char *x = va_arg(ap, char *);
	int tix = strlen(x);
	for ( ;width > tix; width-- ) printc(padmode?'0':' '); /* FIXME */
	while ( *x ) {
	  printc(*x);
	  x++;
	}
      }
      else { printc('%'); printc(*format); }
    }
    else printc(*format);
    format++;
  }
}
