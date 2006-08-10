#include <armsim.h>
#include <stdlib.h>

#define MUL_INST
#ifdef MUL_INST
inline int mul(int a, int b) { return a*b; }
#else
int mul(int a, int b)
{
    int result = 0;
    while (b) {
	if (b & 1)
	    result += a;
	a = a<<1;
	b = b>>1;
    }
    return result;
}
#endif

/* Translation of prime.pl that produces prime factors of input argument. */

/* A 32 bit number can't have more than 32 factors (2**32 > 0xffffffff). */
int factors[32];
int nFactors = 0;

/* Returns the smallest factor of p.  If p is prime, it returns p.
 *
 * For efficiency it works by unrolling the loop and testing several factors on
 * each iteration.  Since we don't have sqrt, ...
 */
int PrimeFactors(int p)
{
    if (p < 2)
	return p;
    int i;				/* trial factor */
    int q, r;				/* quotient, reduced (p - p%i) */
    if ((i=2, mul((q=p/i), i) == p) ||
	(i=3, mul((q=p/i), i) == p) || 
	(i=5, mul((q=p/i), i) == p)) {
	factors[nFactors++] = i;
	return PrimeFactors(q);
    }
    if (q < i)
	return factors[nFactors++] = p;

    /* We've eliminated the factors of 2, 3 & 5 so we can sieve out those
     * factors and test only numbers of the form 30*n +/- 1,7,11,13.  In each
     * 30 numbers, two eliminates 15 factors, three eliminates 5 more, and five
     *  eliminates 2 more, leaving only 8 to check.  At least as much time
     * savings, however, comes from reduced loop overhead. */

    i = 7;
    do {
	if ((r=mul((q=p/i), i)) == p) break;
	i += 4;
	if ((r=mul((q=p/i), i)) == p) break;
	i+=2;
	if ((r=mul((q=p/i), i)) == p) break;
	i += 4;
	if ((r=mul((q=p/i), i)) == p) break;
	i+=2;
	if ((r=mul((q=p/i), i)) == p) break;
	i += 4;
	if ((r=mul((q=p/i), i)) == p) break;
	i+=6;
	if ((r=mul((q=p/i), i)) == p) break;
	i+=2;
	if ((r=mul((q=p/i), i)) == p) break;
	i+=6;
    } while (q >= i);
    if (r == p) {
	factors[nFactors++] = i;
	return PrimeFactors(q);
    }
    return factors[nFactors++] = p;	/* its prime */
}

int atod(char *num)
{
    char c = *num;
    int neg = 0;
    if (c == '-')
	c = *num++, neg = 1;
    int d = 0;
    while (c = *num++) {
	if (c < '0' || c > '9')
	    return neg ? -d : d;
	d = mul(d, 10) + c-'0';
    }
    return neg ? -d : d;
}

void doprime(int p) {
    nFactors = 0;
    PrimeFactors(p);
    if (nFactors == 1)
	printf("%d is prime\n", p);
    else {
      int i;
	printf("%d has factors:", p);
	for (i = 0; i<nFactors; i++)
	    printf(" %d", factors[i]);
	printf("\n");
    }
}

int main(int argc, char *argv[])
{
#ifdef NOARMSIM
    if (argc <= 1) {
	printf("Usage: %s <integer>\n", argv[0]);
	exit(1);
    }
    int p = atod(argv[1]);
    doprime(p);
#else
    int i;
    for (i=2;i<=50;i++) {
      doprime(i);
    }
    int j = 7*11*13*17*19;
    for (i=j-15;i<=j+15;i++) {
      doprime(i);
    }
    j = 23*29*31*37;
    for (i=j-15;i<=j+15;i++) {
      doprime(i);
    }
#endif
    return 0;
}
