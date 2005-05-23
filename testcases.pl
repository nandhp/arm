#!/usr/bin/perl
my @n = (0, 2**16, 2**31);
my @nn = map(($_-2,$_-1,$_,$_+1,$_+2), @n);
#my @nn = map $_&0xffffffff, @nn;

sub to32 ($) {
    my $v = shift;
    $v %= 2**32;
}

sub negative ($) {
    to32(shift) >= 2**31
}

sub signed ($) {
    my $v = shift;
    #$v & 0x80000000 ? $v-2**32 : $v
    $v = to32($v);
    negative($v) ? $v-2**32 : $v
}

sub unsigned ($) {
    to32(shift);
}

for my $a (@nn) {
    for my $b (@nn) {
	my $sum = unsigned(signed($a)+signed($b));
	my $dif = unsigned(signed($a)-signed($b));
	my $cmp = signed($a) <=> signed($b);
	my $ucmp = $a <=> $b;
	printf STDERR "%08x %08x c=%-2d u=%-2d +%08x -%08x (%d, %d)\n",
	  $a, $b, $cmp, $ucmp, $sum, $dif, signed($sum), signed($dif);
	printf " SUBS R0, &%08x, &%08x\n",$a,$b;
	printf " ADD R1, &%08x, &%08x\n",$a,$b;
	if ( $cmp == -1 ) {
	    print " DIEGT\n DIEEQ\n\n"
	}
	elsif ( $cmp == 1 ) {
	    print " DIELT\n DIEEQ\n\n";
	}
	elsif ( $cmp == 0 ) {
	    print " DIEGT\n DIELT\n DIENE\n";
	}
	printf " CMP R0, &%08x\n DIENE\n DIEGT\n DIELT\n",$dif;
	printf " CMP R1, &%08x\n DIENE\n DIEGT\n DIELT\n",$sum;
    }
}
