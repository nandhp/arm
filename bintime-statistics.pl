#!/usr/bin/perl
use List::Util qw(sum);

file:
while (<>) {
    next unless /^real/;
    while (my ($type, $min, $sec) = /^(\w+)\s+(\d+)m([\d.]+)s/) {
	my $sec = $min*60+$sec;
	push @{$types{$type}}, $sec;
	last file unless defined($_ = <>);
    }
}
for my $k (keys %types) {
    my @v = @{$types{$k}};
    my $n = @v;
    my $s = sum @v;
    my $sqs = $s**2;
    my $ssq = sum map $_**2, @v;
    printf "%4s avg: %5.2f, stdev: %4.3f\n",
	$k, $s/$n, $n > 1 ? sqrt(($ssq - $sqs/$n)/($n-1)) : 0;
}
