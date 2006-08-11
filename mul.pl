#!/usr/bin/perl
#use integer;

# The MUL (multiply with 32 bit result) and MLA (multiply and accumulate)
# instructions are present in all architectures.  The M variant also adds 4
# multiply instrctions with long (64) bit results.

# With "S" specified, the N and Z bits are set.
sub mul {
    my ($rm, $rs, $ra) = @_;
    $rm &= 0xffffffff;
    $rs &= 0xffffffff;
    my ($rmh, $rml) = (($rm>>16)&0xffff, $rm & 0xffff);
    my ($rsh, $rsl) = (($rs>>16)&0xffff, $rs & 0xffff);
    my $res = ((($rml*$rsh+$rmh*$rsl) % 0x10000 )<<16) + $rml*$rsl;
#   my $res = $rm * $rs;
    $res %= 2**32;
    $res += $ra & 0xffffffff if defined($ra);
    $newN = ($res & 0x80000000) ? 1 : 0;
    $newZ = $res ? 0 : 1;
    ($res, $newN, $newZ)
}

print "\tB    main\n";
my @n = (1, -1, 2, -7, 0, 0xa0000000, 0x7000, 0xd000);
my @nl= ('sa', 'sb', 'sc', 'sd', 'se', 'sf', 'sg', 'sh');
foreach (my $i=0;$i<=$#n && $i<=$#nl;$i++) {
    print "$nl[$i]:\tDCW  #$n[$i]\n";
}
print "\nmain:\n";
for ($i = 0; $i <= $#n; $i++ ) {
    my $a = $n[$i];
    my $al= $nl[$i];
    for (my $j = 0; $j <= $#n; $j++ ) {
	my $b = $n[$j];
	my $bl= $nl[$j];
	my @R = mul($a, $b);
	printf "@ %d x %d = %d = 0x%x (N=%d Z=%d)\n",
	  $a, $b, convert_to_signed($R[0]), @R;
	my ($N,$Z) = @R[1..2];
	print "\tLDR  R1, $al\n";
	print "\tLDR  R2, $bl\n";
	print "\tMULS R0, R1, R2\n";
	print "\tDIE".($Z?'NE':'EQ')."\n";
	print "\tDIE".($N?'PL':'MI')."\n";
	print "\tLDR  R3, [R15, #0]\n";
	print "\tBX   R15\n";
	printf"\tDCW  &%X\n",$R[0];
	print "\tCMP  R0, R3\n";
	print "\tDIENE\n";
	print "\n";
    }
}
print "\n\nEND\n";

# from arm.pl
# NOTE -- Slightly fixed by moving the $size > 1 test down one line.
sub convert_to_signed {
    my ($bits, $size) = @_;
    $size = 32 unless $size;
    ($size > 1 && $size <= 32) or die;
    my $max = (2 ** $size);         # one more than max unsigned value
    $bits %= $max;
    my $n = $bits;
    if ($bits & ($max/2)) {          # negate if high bit is set
        $n = -($max - $bits);
    }
    return $n;
}
