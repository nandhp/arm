#!/usr/bin/perl
# Do a demo
if ( $ARGV[0] =~ m/p/ ) {
    my $cls = "\e[H\e[J"; my $x = ''; $|=1;
    while ( 1 ) {
	#syswrite(STDOUT,$cls);
	print "$cls";#print '1';
	system './arm.pl -q --readelf a.out 2>/dev/null';
	#open DEMOSRC, "./arm.pl a.out 2>/dev/null |";
	#syswrite STDOUT,$x while sysread DEMOSRC,$x,1,0;
	sleep 3;
    }
    exit;
}
my $cls = "\e[H\e[2J"; my $x = ''; $|=1;
open FIFO, ">/tmp/armdemo"; # Must be existing fifo
while ( 1 ) {
    syswrite($_,$cls) foreach FIFO, STDOUT;
    open DEMOSRC, "./arm.pl a.out 2>/tmp/armdemo |";
    syswrite STDOUT,$x while sysread DEMOSRC,$x,1,0;
    sleep 3;
}
