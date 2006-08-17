#include <armsim.h>
#include <string.h>

/* from lifewin/rc4.cpp - 19-Jun-2003 */

typedef struct rc4 {
    unsigned i, j;
    unsigned char s[256];
} *rc4_t;

void rc4_InitState(rc4_t s)
{
    unsigned x;
    for (x=0; x<256; x++) s->s[x] = x;
    s->i = s->j = 0;
}

/* Just reset counters, but leave state variable alone. */
inline void rc4_Reset(rc4_t s) { s->i = s->j = 0; }

void rc4_Key(rc4_t s, unsigned char *k, unsigned l)
{
    unsigned ki = 0;
    unsigned x,y;
    rc4_InitState(s);
    for (x=y=0; x<256; x++, ki=(ki+1)%l) {
	unsigned char tmpi = s->s[x];
	y = (y + tmpi + k[ki]) & 0xff;
	s->s[x] = s->s[y];
	s->s[y] = tmpi;
    }
    s->i = s->j = 0;
}

void rc4_KeyByte(rc4_t s, unsigned char k)
{
    unsigned char tmpi = s->s[s->i];
    s->j = (s->j + tmpi + k) & 0xff;
    s->s[s->i] = s->s[s->j];
    s->s[s->j] = tmpi;
    s->i = (s->i+1) & 0xff;
}

unsigned char rc4_Byte(rc4_t s)
{
    unsigned char tmpi, tmpj, b;
    s->i = (s->i+1) & 0xff;
    tmpi = s->s[s->i];
    s->j = (s->j+tmpi) & 0xff;
    tmpj = s->s[s->i] = s->s[s->j];
    s->s[s->j] = tmpi;
    b = s->s[(tmpi + tmpj) & 0xff];
    return b;
}

#if 0
// functions for using RC4 as a random number generator
__inline void rc4_RandomSeed(rc4_t s, unsigned seed)
  { rc4_Key(s, (unsigned char *)&seed, sizeof(seed)); }
#endif

#if 0
typedef __int64 int64;
typedef unsigned __int64 u_int64;

// randMax must be a power of two
unsigned rc4_RandomBits(rc4_t s, unsigned randMax)
{
    unsigned rand = 0;
    unsigned bits = 0;
    do {
	rand = (rand << 8) + rc4_Byte(s);
	bits += 8;
    } while (((u_int64)1)<<bits < randMax);
    return rand & (randMax - 1);
}

unsigned rc4_Random(rc4_t s, unsigned randMax)
{
    int64 rand;
    if (((randMax-1) & randMax) == 0)
	return rc4_RandomBits(s, randMax);
    // need 8 extra bits to ensure that mod doesn't bias results (much)
    rand = rc4_Byte(s);
    while (rand < (int64)randMax << 8)
	rand = (rand<<8) + rc4_Byte(s);
    return (unsigned)(rand % randMax);
}
#endif

static void rc4_TestOne(unsigned char *k, unsigned kl,
			unsigned char *p, unsigned pl, unsigned char *c)
{
    struct rc4 t;
    unsigned i;
    rc4_Key(&t, k, kl);
    for (i=0; i<pl; i++) {
	unsigned char cx = rc4_Byte(&t) ^ p[i];
	if (cx != c[i]) {
	    assert(!"mismatch");
	}
    }
}

int rc4_SelfTest(void)
{
    unsigned char p1[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    unsigned char k1[] = {0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF};
    unsigned char c1[] = {0x74, 0x94, 0xC2, 0xE7, 0x10, 0x4B, 0x08, 0x79};
    unsigned char p2[] = {0xdc, 0xee, 0x4c, 0xf9, 0x2c};
    unsigned char k2[] = {0x61, 0x8a, 0x63, 0xd2, 0xfb};
    unsigned char c2[] = {0xf1, 0x38, 0x29, 0xc9, 0xde};
    unsigned char p3[] = {
	0x52, 0x75, 0x69, 0x73, 0x6c, 0x69, 0x6e, 0x6e,
	0x75, 0x6e, 0x20, 0x6c, 0x61, 0x75, 0x6c, 0x75,
	0x20, 0x6b, 0x6f, 0x72, 0x76, 0x69, 0x73, 0x73,
	0x73, 0x61, 0x6e, 0x69, 0x2c, 0x20, 0x74, 0xe4,
	0x68, 0x6b, 0xe4, 0x70, 0xe4, 0x69, 0x64, 0x65,
	0x6e, 0x20, 0x70, 0xe4, 0xe4, 0x6c, 0x6c, 0xe4,
	0x20, 0x74, 0xe4, 0x79, 0x73, 0x69, 0x6b, 0x75,
	0x75, 0x2e, 0x20, 0x4b, 0x65, 0x73, 0xe4, 0x79,
	0xf6, 0x6e, 0x20, 0x6f, 0x6e, 0x20, 0x6f, 0x6e,
	0x6e, 0x69, 0x20, 0x6f, 0x6d, 0x61, 0x6e, 0x61,
	0x6e, 0x69, 0x2c, 0x20, 0x6b, 0x61, 0x73, 0x6b,
	0x69, 0x73, 0x61, 0x76, 0x75, 0x75, 0x6e, 0x20,
	0x6c, 0x61, 0x61, 0x6b, 0x73, 0x6f, 0x74, 0x20,
	0x76, 0x65, 0x72, 0x68, 0x6f, 0x75, 0x75, 0x2e,
	0x20, 0x45, 0x6e, 0x20, 0x6d, 0x61, 0x20, 0x69,
	0x6c, 0x6f, 0x69, 0x74, 0x73, 0x65, 0x2c, 0x20,
	0x73, 0x75, 0x72, 0x65, 0x20, 0x68, 0x75, 0x6f,
	0x6b, 0x61, 0x61, 0x2c, 0x20, 0x6d, 0x75, 0x74,
	0x74, 0x61, 0x20, 0x6d, 0x65, 0x74, 0x73, 0xe4,
	0x6e, 0x20, 0x74, 0x75, 0x6d, 0x6d, 0x75, 0x75,
	0x73, 0x20, 0x6d, 0x75, 0x6c, 0x6c, 0x65, 0x20,
	0x74, 0x75, 0x6f, 0x6b, 0x61, 0x61, 0x2e, 0x20,
	0x50, 0x75, 0x75, 0x6e, 0x74, 0x6f, 0x20, 0x70,
	0x69, 0x6c, 0x76, 0x65, 0x6e, 0x2c, 0x20, 0x6d,
	0x69, 0x20, 0x68, 0x75, 0x6b, 0x6b, 0x75, 0x75,
	0x2c, 0x20, 0x73, 0x69, 0x69, 0x6e, 0x74, 0x6f,
	0x20, 0x76, 0x61, 0x72, 0x61, 0x6e, 0x20, 0x74,
	0x75, 0x75, 0x6c, 0x69, 0x73, 0x65, 0x6e, 0x2c,
	0x20, 0x6d, 0x69, 0x20, 0x6e, 0x75, 0x6b, 0x6b,
	0x75, 0x75, 0x2e, 0x20, 0x54, 0x75, 0x6f, 0x6b,
	0x73, 0x75, 0x74, 0x20, 0x76, 0x61, 0x6e, 0x61,
	0x6d, 0x6f, 0x6e, 0x20, 0x6a, 0x61, 0x20, 0x76,
	0x61, 0x72, 0x6a, 0x6f, 0x74, 0x20, 0x76, 0x65,
	0x65, 0x6e, 0x2c, 0x20, 0x6e, 0x69, 0x69, 0x73,
	0x74, 0xe4, 0x20, 0x73, 0x79, 0x64, 0xe4, 0x6d,
	0x65, 0x6e, 0x69, 0x20, 0x6c, 0x61, 0x75, 0x6c,
	0x75, 0x6e, 0x20, 0x74, 0x65, 0x65, 0x6e, 0x2e,
	0x20, 0x2d, 0x20, 0x45, 0x69, 0x6e, 0x6f, 0x20,
	0x4c, 0x65, 0x69, 0x6e, 0x6f};
    unsigned char k3[] = {0x29, 0x04, 0x19, 0x72, 0xfb, 0x42, 0xba, 0x5f,
			  0xc7, 0x12, 0x77, 0x12, 0xf1, 0x38, 0x29, 0xc9};
    unsigned char c3[] = {
	0x35, 0x81, 0x86, 0x99, 0x90, 0x01, 0xe6, 0xb5,
	0xda, 0xf0, 0x5e, 0xce, 0xeb, 0x7e, 0xee, 0x21,
	0xe0, 0x68, 0x9c, 0x1f, 0x00, 0xee, 0xa8, 0x1f,
	0x7d, 0xd2, 0xca, 0xae, 0xe1, 0xd2, 0x76, 0x3e,
	0x68, 0xaf, 0x0e, 0xad, 0x33, 0xd6, 0x6c, 0x26,
	0x8b, 0xc9, 0x46, 0xc4, 0x84, 0xfb, 0xe9, 0x4c,
	0x5f, 0x5e, 0x0b, 0x86, 0xa5, 0x92, 0x79, 0xe4,
	0xf8, 0x24, 0xe7, 0xa6, 0x40, 0xbd, 0x22, 0x32,
	0x10, 0xb0, 0xa6, 0x11, 0x60, 0xb7, 0xbc, 0xe9,
	0x86, 0xea, 0x65, 0x68, 0x80, 0x03, 0x59, 0x6b,
	0x63, 0x0a, 0x6b, 0x90, 0xf8, 0xe0, 0xca, 0xf6,
	0x91, 0x2a, 0x98, 0xeb, 0x87, 0x21, 0x76, 0xe8,
	0x3c, 0x20, 0x2c, 0xaa, 0x64, 0x16, 0x6d, 0x2c,
	0xce, 0x57, 0xff, 0x1b, 0xca, 0x57, 0xb2, 0x13,
	0xf0, 0xed, 0x1a, 0xa7, 0x2f, 0xb8, 0xea, 0x52,
	0xb0, 0xbe, 0x01, 0xcd, 0x1e, 0x41, 0x28, 0x67,
	0x72, 0x0b, 0x32, 0x6e, 0xb3, 0x89, 0xd0, 0x11,
	0xbd, 0x70, 0xd8, 0xaf, 0x03, 0x5f, 0xb0, 0xd8,
	0x58, 0x9d, 0xbc, 0xe3, 0xc6, 0x66, 0xf5, 0xea,
	0x8d, 0x4c, 0x79, 0x54, 0xc5, 0x0c, 0x3f, 0x34,
	0x0b, 0x04, 0x67, 0xf8, 0x1b, 0x42, 0x59, 0x61,
	0xc1, 0x18, 0x43, 0x07, 0x4d, 0xf6, 0x20, 0xf2,
	0x08, 0x40, 0x4b, 0x39, 0x4c, 0xf9, 0xd3, 0x7f,
	0xf5, 0x4b, 0x5f, 0x1a, 0xd8, 0xf6, 0xea, 0x7d,
	0xa3, 0xc5, 0x61, 0xdf, 0xa7, 0x28, 0x1f, 0x96,
	0x44, 0x63, 0xd2, 0xcc, 0x35, 0xa4, 0xd1, 0xb0,
	0x34, 0x90, 0xde, 0xc5, 0x1b, 0x07, 0x11, 0xfb,
	0xd6, 0xf5, 0x5f, 0x79, 0x23, 0x4d, 0x5b, 0x7c,
	0x76, 0x66, 0x22, 0xa6, 0x6d, 0xe9, 0x2b, 0xe9,
	0x96, 0x46, 0x1d, 0x5e, 0x4d, 0xc8, 0x78, 0xef,
	0x9b, 0xca, 0x03, 0x05, 0x21, 0xe8, 0x35, 0x1e,
	0x4b, 0xae, 0xd2, 0xfd, 0x04, 0xf9, 0x46, 0x73,
	0x68, 0xc4, 0xad, 0x6a, 0xc1, 0x86, 0xd0, 0x82,
	0x45, 0xb2, 0x63, 0xa2, 0x66, 0x6d, 0x1f, 0x6c,
	0x54, 0x20, 0xf1, 0x59, 0x9d, 0xfd, 0x9f, 0x43,
	0x89, 0x21, 0xc2, 0xf5, 0xa4, 0x63, 0x93, 0x8c,
	0xe0, 0x98, 0x22, 0x65, 0xee, 0xf7, 0x01, 0x79,
	0xbc, 0x55, 0x3f, 0x33, 0x9e, 0xb1, 0xa4, 0xc1,
	0xaf, 0x5f, 0x6a, 0x54, 0x7f};
    rc4_TestOne(k1, sizeof(k1), p1, sizeof(p1), c1);
    rc4_TestOne(k2, sizeof(k2), p2, sizeof(p2), c2);
    rc4_TestOne(k3, sizeof(k3), p3, sizeof(p3), c3);
    return 0;
}

int main()
{
    int rc = rc4_SelfTest();
    if (rc != 0)
	return 1;

    /* use rc4 as hash */
    {
	struct rc4 t;
	rc4_InitState(&t);
	const char *foo = "foo";
	const unsigned foolen = strlen(foo);
	const unsigned char digest[] = {
	    0xc0, 0x80, 0x02, 0x8c, 0x04, 0x65, 0xad, 0x97, 0xe1, 0x38,
	    0x98, 0x20, 0x5a, 0xc1, 0x3a, 0x4d, 0x26, 0x35, 0xce, 0x87 };
	const unsigned digestSize = sizeof(digest);
	unsigned i;
	for (i = 0; i<foolen; i++) {
	    rc4_KeyByte(&t, foo[i]);
	}
	for (i=0; i<256; i++)
	    rc4_Byte(&t);		/* mix for 256 cycles */
	rc4_Reset(&t);
	printf("Hash of '%s' is ", foo);
	const unsigned char *d = digest;
	for (i = 0; i<digestSize; i++) {
	    unsigned char b = rc4_Byte(&t);
	    printf("%02x", b);
	    assert(b == *d++);
	}
	printf("\n");
    }

}