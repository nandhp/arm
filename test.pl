use Benchmark qw/timethese cmpthese/;

my $count;
sub WithRef {
    $count += keys %{$_[0]};
}

sub WithoutRef {
    my (%foo) = (@_);
    $count += keys %foo;
}

sub {
    my %foo = ();
    foreach (0..500) {
	$foo{$_} = rand;
    }

    my $result = timethese(10000, { 'WithRef' => sub {WithRef(\%foo)}, 'WithoutRef' => sub {WithoutRef(%foo)} });
    cmpthese( $result );
}->();
print "$count\n";
