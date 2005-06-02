#!/usr/bin/perl
use strict;
use warnings;
use integer;
use Getopt::Long qw(:config gnu_getopt);
use Pod::Usage;
use Term::ReadLine;

my $VERSION='20050602';# yyyymmdd

$| = 1;

my $v = 0;
my $help = 0;
my $man = 0;
my $q = 0;
my $d = 0;
GetOptions('debug|d' => \$d, 'verbose|v' => \$v, 'quiet|q' => \$q, 'help|h|?' => \$help, 'man' => \$man, 'version' => \&show_version) or show_help();
show_help(1) if $help;
show_help(2) if $man;

my $term = new Term::ReadLine 'ARM Debugger';
my $prompt = '<DB> ';
my $OUT = \*STDOUT;
my $debugnext = 1; # Stop at next statement
my $defaultc = 0;
if ( $d ) {
    #$q=0;
    print "\narm.pl debugger, version $VERSION\n\nTry 'perldoc arm.pl' for help\n\n";
    $OUT = $term->OUT if $term->OUT;
#    print "Spawning debugger...\n";
#    my @args = (
#		$v?('-'.('v'x$v)):'',
#		$q?'-q':'',
#	       );
#    system('perl','-d','arm.pl',
#	   @args,
#	   @ARGV);
#    exit();
}

$v = -1 if $q;

=head1 NAME

arm.pl - Interpret ARM Assembler in Perl

=head1 SYNOPSIS

arm.pl [options] [file ...]

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--verbose>, B<-v>

Be verbose about parsing and execution. See the "VERBOSITY" section in
the full documentation for information about the available verbosity
levels.

=item B<--quiet>, B<-q>

Be quiet. Do not show each instruction as it is executed

=item B<--man>

Display the full documentation, for which you may want to use a pager.

=item B<--debug>, B<-d>

Run the provided assembler code under the debugger. Even though this
switch no longer does the old "re-run arm.pl under perldebug(1)" it is
still pretty cool.

=item B<--version>

Display the arm.pl version number and check for updates

=back

=head1 DESCRIPTION

B<arm.pl> will parse the given input file(s) as ARM assembler and
attempt to execute them.

=head1 ARCHITECTURE DOCUMENTATION

Documentation for the ARM Architecture is available from the following
sources:

=over 8

=item B<src/docs>

The src/docs directory contains most of the documentation on the ARM
Architcture. It is available in the main tree only, and is not
included in the source distribution.

=item B<The ARM Status Blog>

The ARM Status Blog includes all of the documentation available in
src/docs as well as release distributions and more.

L<http://nand.homelinux.com:8888/~nand/blosxom/blosxom.cgi>

=back

=head1 DEBUGGER

The arm.pl interactive debugger will be used whenever the program is
run with the B<--debug> (B<-d>) switch. The following commands are
available in the debugger:

=over 8

=item B<b>[ [I<filename>:]I<line>]

Set a breakpoint. If no filename is specified, defaults to the current
file, and if no line number is specified, defaults to the current line.

=item B<d>[ [I<filename>:]I<line>]

Clear a previously-set breakpoint. See B<b>.

=item B<l>[ [I<filename>][:][I<line>]]

List the next ten lines of I<filename>, starting at I<line> or
defaulting to various sensible defaults which involve you being able
to enter B<l> repeatedly to view more of the file, like the perl
debugger.

=item B<v>[ [I<filename>][:][I<line>]]

Same as B<l>, except the first window it displays will also show
several lines prior to the specified (or default) line.

=item B<r>[x|b]I<number>

Display the contents of the given register. If B<x> is provided,
displays it in hex, if B<b> is provided, displays it as byte(s).

=item B<n>

Execute the next instruction and display another prompt.

=item B<c>

Execute the next instruction and continue until a breakpoint is
reached or the program terminates.

=item B<q>

Quit.

=back

=head1 BUGS

None

=head1 AUTHOR

nandhp <nandhp AT myrealbox WITHNOSPAM com>

=cut

sub show_version {
    print "arm.pl version $VERSION\n\nChecking for updates...";
    my @vup = split("\n",eval('use LWP::Simple;return get("http://nand.homelinux.com:8888/~nand/blosxom/version.cgi")')||'');
    print "\n\n";
    if ( !@vup ) {
	print "There was an error checking for updates.\nPlease try back later.\n";
    }
    elsif ( $vup[0] < $VERSION ) {
	print "You are running the development version.\nThere are no updates available.\n";
    }
    elsif ( $vup[0] == $VERSION ) {
	print "You are running the latest version.\nThere are no updates available.\n";
    }
    elsif ( $vup[0] > $VERSION ) {
	print "The latest version is $vup[0].\nFor more information on this version, visit\n$vup[1]\n";
    }
    exit(1);
}

sub show_help {
    my ($arg) = @_;
    $arg ||= 0;
    if ( $arg == 0 ) {
	pod2usage(-verbose => 0,-msg => " ");
    }
    elsif ( $arg == 1 ) {
	pod2usage(-verbose => 1,-msg => "arm.pl version $VERSION\n");
    }
    elsif ( $arg == 2 ) {
	pod2usage(-verbose => 2,-msg => "arm.pl version $VERSION\n");
    }
    else {
	pod2usage(-verbose => 1,-msg => "arm.pl version $VERSION\n");
    }
    exit(1);
}

sub vprint($)   { print @_ if $v >= 1 }
sub vvprint($)  { print @_ if $v >= 2 }
sub vvvprint($) { print @_ if $v >= 3 }

#$conds{$_} = 1 foreach qw(a b c);
my %conds = (
	     EQ => 1,# Equal: If the Z flag is set after a comparison.
	     NE => 1,# Not equal: If the Z flag is clear after a comparison.
	     CS => 1,# Carry Set: Set if the C flag is set after an
                     # arithmetical operation OR a shift operation,
                     # the result of which cannot be represented in
                     # 32bits. You can think of the C flag as the 33rd
                     # bit of the result.
	   # HS => 1,# Unsigned higher or same
	     CC => 1,# Carry Clear: The reverse of CS.
	   # LO => 1,# Unsigned lower
	     MI => 1,# Negative: If the N flag is set after an arithmetic op.
	     PL => 1,# Positive or zero: If the N flag is clear after
                     # an arithmetical operation. For the purposes of
                     # defining 'plus', zero is positive because it
                     # isn't negative...
	     VS => 1,# Overflow: If V flag set after arithmetic op,
                     # the result of which won't fit into a 32bit dest reg.
	     VC => 1,# No overflow: If the V flag is clear, the reverse of VS.
	   # HI => 1,# Unsigned higher: If after a comparison the C
                     # flag is set AND the Z flag is clear.
	   # LS => 1,# Unsigned lower or same: If after a comparison
                     # the C flag is clear OR the Z flag is set.
	     GE => 1,# Signed greater than or equal: If after a comparison...
	             # the N flag is set AND the V flag is set
	             # or...
	             # the N flag is clear AND the V flag is clear.
	     LT => 1,# Signed less than: If after a comparison...
	             # the N flag is set AND the V flag is clear
	             # or...
	             # the N flag is clear AND the V flag is set.
	     GT => 1,# Signed greater than: If after a comparison...
	             # the N flag is set AND the V flag is set
	             # or...
	             # the N flag is clear AND the V flag is clear
	             # and...
	             # the Z flag is clear.
	     LE => 1,# Signed less than or equal: If after a comparison...
	             # the N flag is set AND the V flag is clear
	             # or...
	             # the N flag is clear AND the V flag is set
	             # and...
	             # the Z flag is set.
	     AL => 1,# Always (normally omitted)
	     NV => 1,# Never (do not use, not documented in PDF)
	    );

# This will probably house opcodes at some point.

my %instructions = (
		    # Unimplemented instructions
		    LDM => 1,
		    STM => 1,
		    BIC => 1,
		    TEQ => 1,
		    TST => 1,
		    MSR => 1,
		    MRS => 1,
		    MVN => 1,
		    MLA => 1,
		    MUL => 1,
		    RSC => 1,
		    RSB => 1,

		    # Implemented instructions
		    B   => 1,
		    BL  => 1,
		    MOV => 1,
		    SUB => 1,
		    CMP => 1,
		    ADD => 1,
		    LDR => 1,
		    STR => 1,
		    # Beta instructions
		    EOR => 1,
		    # Alpha instructions
		    CMN => 1,
		    ADC => 1,
		    SBC => 1,
		    ORR => 1,
		    AND => 1,

		    # Implemented/unsupported instructions
		    SWI => 1,

		    # Nonstandard instructions
		    NOOP => 3,
		    DIE => 3,
		    END => 3,
		    OUT => 3,
		   );
my %extra = (
	     S  => 1,
	     T  => 1,
	     B  => 1,
	     BT => 1,
	     IA => 1,
	     FD => 1,
	     IB => 1,
	     DA => 1,
	     DB => 1,
	     ED => 1,
	     FA => 1,
	     EA => 1,
	    );

my %operand_flags = (
		     LSL => 1,
		     LSR => 1,
		     ASR => 1,
		     ROR => 1,
		     RRX => 1,
		    );
my @program = ();
my @lines = ();
my @breaks = ();
my %labels = ();
# A program is an array of arrays.
#
# Each array is an instruction. The first item is the instuction name
# -opcode if you insist- of the instruction. The executor takes each
# array, looks at the first element, and passes it to the appropriate
# code: The code for "BRANCH" say.
#
# Labels are stored seperately and are array indexes.
#
# Example:
#
#  B foo
# bar:
#  B baz
# foo:
#  B bar
# baz:
#
# Which looks something like this:
#
# @program = (				%labels = (
#   0 => ['B', 'AL', '', 'foo'],	  'bar' => 1,
#   1 => ['B', 'AL', '', 'baz'],	  'foo' => 2,
#   2 => ['B', 'AL', '', 'bar'],	  'baz' => 3,
#   3 => 0)				)
#
# (Conditionals are cleverly ignored in this example)
#
# A branch implementation might work like this:
# elsif ( $ins[0] eq 'B' ) {
#     if ( $ins[1] && exists($labels{$ins[1]}) ) {
#         $reg[15]=$labels{$ins[1]};
#     }
#     else { throw("Error parsing branch. No label $ins[1]") }
# }
#

my $memory = ''; # Big endian
$memory .= chr(0).chr(0).chr(1).chr(1);
#print unpack("N",$memory),"\n";
#exit;

my $condmatch = join('|',keys %conds);
my $insmatch = join('|',keys %instructions);
my $xmatch = join('|',keys %extra);
my $fopmatch = join('|',keys %operand_flags);

print "Parsing source...\n";

# Process the program
my $insnum = 0;
my $mempos = 0;
my $includefn = scalar(@ARGV)>1?1:0;
my $lastlabel='';

while (my $line = <>) {
    $line =~ s/[\r\n]//g;
    vprint "$line \n";
    next if $line =~ /^\s*;/;
    next if $line =~ /^#!/;
    next if $line =~ /^\s*$/;

    $line =~ s/;.+$//; # FIXME
    $line =~ s/\s*$//;

    # Check for a label
    if ( $line =~ s/^(\w+):(\s+|$)// ) {
	my ($label,$ws) = (lc $1,$2);
	if ( $labels{$label} ) {
	    print "WARN: Duplicate label $1\n";
	}
	$lastlabel=$label;
	vprint "Memory: $mempos\t Label: $label\n";
	$labels{$label}=$mempos;
	next unless $ws;
    }

    $line =~ s/^\s*//;

    if ( $line =~ /^DC([BDW])\s+(.+)$/i ) {
	# FIXME
	my $bdw = uc $1;
	my $vals = $2;
	vprint "Processing DC$1...\n";
	if ( $bdw eq 'D' ) {		# Define Constant Data doesn't act
	    $bdw = 'W';			# constant here... See ARMBook p29
	    #print "WARN: Processing DCD as DCW\n";
	}

	# A quote followed by a bunch of stuff and then another quote
	# that is not preceeded by a backslash.
	$vals =~ s/\"(.+?)(?<!\\)\"/MungeString($1)/ge;
	if ( $bdw eq 'B' ) {
	    $labels{$lastlabel}="$mempos|1";
	    foreach ( split ',', $vals ) {
		s/^\s*|\s*$//g;
		setmem($mempos,translate($_),1);
		vprint "$_ stored at $mempos (size 1) label $lastlabel=$labels{$lastlabel}\n";
		$mempos++;
	    }
	}
	elsif ( $bdw eq 'W' ) {
	    while ( $mempos%4 ) {	# ALIGN
		setmem($mempos,0,1);
		$mempos++;
	    }
	    $labels{$lastlabel}="$mempos|0";
	    foreach ( split ',', $vals ) {
		s/^\s*|\s*$//g;
		setmem($mempos,translate($_),0);
		vprint "$_ stored at $mempos (size 4) label $lastlabel=$labels{$lastlabel}\n";
		$mempos+=4;
	    }
	}
	else { throw("Bad DC{X} DC$1.\n") }
	$lastlabel='';
	next;
    }

    $lastlabel='';

    while ( $mempos%4 ) {		# ALIGN
	setmem($mempos,0,1);
	$mempos++;
    }

    next if $line =~ /^ALIGN\s*/i;	# ALIGN is automatic

    # Parse instruction
    my ($ins,$cond,$extra,$params) = $line =~ /^($insmatch)($condmatch)?($xmatch)?(?:\s+(.+))?$/i or throw("Parse Error");
    $cond ||= "AL";
    ($ins,$cond,$extra) = (uc $ins,uc $cond,uc $extra); # Uppercase some
    vprint "Number: $insnum\nInstruction: $ins\nCondition: $cond\nExtra: $extra\n";
    $params ||= "";
    my @params = ();
    # FIXME: Flexible Operand 2
    while ( $params =~ /\s*([\-A-Z0-9#&x]+\s*(,\s*($fopmatch).*)?|\[R\d+(,\s*($fopmatch)?\s*(?:#-?\d+|R\d+|PC))?\]|=?\w+)\s*(,\s*|$)/gi ) {
	push @params, $1;
	vprint "Param: $1\n";
    }
    my @instruction = ($ins,$cond,$extra);
    push @instruction, @params;
    push @program, \@instruction;
    $lines[$mempos/4] = $includefn?"$ARGV:$.":"$.";
    # TODO: Use real instruction representations
    setmem($mempos,$insnum,0);
    $mempos+=4;

    $insnum++;
    vprint "\n";
}
continue { close ARGV if eof }		# To reset $.
  ;

push @program, 0;			# Last instruction should be 0 - See branch

my $unknownid = 0;

# Run it
my ($N,$Z,$C,$V) = (0,0,0,0);
my $S = 0;
my $B = 0;

my $fopco = 0;

my @reg = ();
print "Begining execution on instruction 0\n";
$reg[15]=8; # PC, 2 ahead, multiply by four
$insnum = 0;

my $rmeight;
my $died = 0;

INSTRUCTION:
while ( $program[$insnum = getmem($rmeight = $reg[15]-8,0)||0] ) {
    my $lineflags = '';

    my $oldpc = $reg[15]; # Save old PC so if it changes we don't increment

    last unless $program[$insnum];
    my @ins = @{$program[$insnum]};

    my $line = 1?'unknown:'.$unknownid:'phantom instruction';
    if ( !defined($lines[$rmeight/4]) ) {
	print "WARN: Unknown source for instruction at memory location $reg[15]-8=$rmeight\n";
	#throw("Bad PC: $reg[15]");
	$lines[$rmeight/4] = $line;
	$unknownid++;
    }
    else { $line = $lines[$rmeight/4] }

    if ( $breaks[$rmeight/4]||0 ) {
	$debugnext = 1;
	$lineflags .= 'b';
    }

    print("$line:".($lineflags||'')."\t".join(' ',@ins[0..2]).' '.join(', ',@ins[3..$#ins])."\n") if ($v > -1 or $debugnext) and !$died;

    if ( $d ) { #Debugger
	my ($readfile,$listline,$startline) = ('',0,0);
	my $debugline;
	print "$died\nUse 'q' to quit the debugger.\n\n" if $died;
	while ( $debugnext && (defined($debugline = $term->readline($prompt))||(print("\n\n"),exit(1))) ) {
	    $term->addhistory($debugline) if $debugline =~ /\S/;
	    $debugline =~ s/^\s*//g;
	    $debugline =~ s/\s*$//g;
	    $debugline =~ s/^\s{2,}/ /g;
	    if ( lc $debugline eq 'q' ) { print "\n";exit(1) }
	    elsif ( lc $debugline =~ /^r([xsb]?)(\d+)$/ ) {
		$reg[$2]||=0;
		if ( $1 eq 'x' or $1 eq 's' ) { # S for compatibility with OUT
		    printf "R$2 = 0x%08x\n",$reg[$2];
		}
		elsif ( $1 eq 'b' ) {
		    my $rid=$2;
		    my $str = pack('N',$reg[$rid]);
		    $str =~ s/^\0+(.+)$/$1/;
		    printf "R$rid = \"%s\"\n",$str;
		}
		else {
		    print "R$2 = $reg[$2]\n";
		}
	    }
	    elsif ( lc $debugline =~ /^([bd])( ([^\s:]*?):?(\d+))?$/ ) {
		my $sr = $1 eq 'b'?1:0;
		if ( !$2 ) {
		    $breaks[$rmeight/4]=$sr;
		    redo INSTRUCTION;
		}
		else {
		    my ($file,$linenum) = ($3,$4);
		    ($file) = $lines[$rmeight/4] =~ /^(.+):\d+$/ unless $file;
		    $file = $ARGV unless $file;

		    my $destindex = 0;
		    my $found = 0;
		    my $bcmp = $includefn?"$file:$linenum":$linenum;
		    foreach ( @lines ) {
			if ( $_ eq $bcmp ) {
			    $breaks[$destindex]=$sr;
			    $found = 1;
			    last;
			}
			$destindex++;
		    }
		    if ( !$found ) {
			print "Can't set breakpoint at $file:$linenum\n";
		    }
		    else {
			redo INSTRUCTION;
		    }
		}
	    }
	    elsif ( lc $debugline =~ /^([vl])( ([^\s:]*?):?(\d+)?)?$/i ) {
		my $view = lc $1 eq 'v'?1:0;

		if ( $3 || $4 || !$readfile || !$listline || !$startline ) {
		    ($readfile,$listline) = ($3,$4);
		    ($readfile) = $lines[$rmeight/4] =~ /^(.+):\d+$/
		      unless $readfile;
		    $readfile = $ARGV unless $readfile;

		    if ( $3 ) { $listline = 1 }
		    else {
			($listline) = $lines[$rmeight/4] =~ /^.+:(\d+)$/
			  unless $listline;
			$listline = $lines[$rmeight/4] unless $listline;
			$startline = $view?$listline-4:$listline;
		    }
		}

		open SCRIPT, $readfile;
		my $readline = 1;
		until ( $readline >= $startline ) {
		    $readline++;
		    <SCRIPT>;
		}
		while ( my $linetxt = <SCRIPT> ) {
		    my $bcmp = $includefn?"$readfile:$readline":$readline;
		    my $found = -1;
		    my $destindex = 0;
		    foreach ( @lines ) {
			next unless defined($_);
			if ( $_ eq $bcmp ) {
			    $found = $destindex;
			    last;
			}
			$destindex++;
		    }
		    if ( $found < 0 ) {
			print "$bcmp\t$linetxt";
		    }
		    else {
			my $lineflags = '';
			$lineflags .= 'b' if $breaks[$destindex]||0;
			$lineflags .= '>>' if $bcmp eq $line;
			$lineflags .= ' ';
			print("$bcmp:".($lineflags||'')."\t$linetxt");
		    }
		    $readline++;
		    last if $readline>$startline+9;
		}
		$startline = $readline;
		if ( eof(SCRIPT) ) {
		    $startline--;
		}
	    }
	    elsif ( lc $debugline =~ /^c$/ or ($debugline eq '' and $defaultc)) {
		if ( $died ) { print "Not running\n";next }
		$debugnext=0;
		$defaultc=1;
		last;
	    }
	    elsif ( lc $debugline eq 'n' or ($debugline eq '' and !$defaultc)) {
		if ( $died ) { print "Not running\n";next }
		$debugnext=1;
		$defaultc=0;
		last;
	    }
	    else { print "Unrecognized command\n" }
	}
	close SCRIPT;
    }
    exit(1) if $died;

    #
    # Format of @ins
    #
    # @ins = ('B', 'AL', '', 'foo');
    #
    # $ins[0] = "Opcode" (%instructions)
    # $ins[1] = Conditional (%conds)
    # $ins[2] = Extra (%extras)
    # $ins[3..$#ins] = Arguments
    #

    # Check conditional
    if ( $ins[1] eq 'AL' ) { }
    elsif ( $ins[1] eq 'NV' ) { $reg[15]+=4; next }
    elsif ( $ins[1] eq 'EQ' ) { vprint "EQ: Z=$Z\n";
				($reg[15]+=4,next) if !$Z } # Skip if NE
    elsif ( $ins[1] eq 'NE' ) { vprint "NE: Z=$Z\n";
				($reg[15]+=4,next) if $Z }
    elsif ( $ins[1] eq 'CS' ) { vprint "CS: C=$C\n";
				($reg[15]+=4,next) if !$C }
    elsif ( $ins[1] eq 'CC' ) { vprint "CC: C=$C\n";
				($reg[15]+=4,next) if $C }
    elsif ( $ins[1] eq 'MI' ) { vprint "MI: N=$N\n";
				($reg[15]+=4,next) if !$N }
    elsif ( $ins[1] eq 'PL' ) { vprint "PL: N=$N\n";
				($reg[15]+=4,next) if $N }
    elsif ( $ins[1] eq 'VS' ) { vprint "VS: V=$V\n";
				($reg[15]+=4,next) if !$V }
    elsif ( $ins[1] eq 'VC' ) { vprint "VC: V=$V\n";
				($reg[15]+=4,next) if $V }
    elsif ( $ins[1] eq 'GE' ) { vprint "GE: N=$N,V=$V,Z=$Z\n";
				($reg[15]+=4,next) if $V != $N }
    elsif ( $ins[1] eq 'LT' ) { vprint "LT: N=$N,V=$V,Z=$Z\n";
				($reg[15]+=4,next) if $V == $N }
    elsif ( $ins[1] eq 'GT' ) { vprint "GT: N=$N,V=$V,Z=$Z\n";
				($reg[15]+=4,next) if $V != $N || $Z }
    elsif ( $ins[1] eq 'LE' ) { vprint "LE: N=$N,V=$V,Z=$Z\n";
				($reg[15]+=4,next) if $V == $N && !$Z  }
    else { throw("Unsupported conditional $ins[1]") }

    # Extra flags
    $S = 0;
    $B = 0;
    if ( $ins[2] eq 'S' ) {
	vprint "TODO: S bits are not stored in R15! S support is Beta!\n";
	$S = 1;
    }
    elsif ( $ins[2] eq 'B' ) { $B = 1 }
    elsif ( $ins[2] ) { throw("Unsupported flag $ins[2]") }

    # Execute instruction
    if ( $ins[0] eq 'B' or $ins[0] eq 'BL' ) { #{B|BL}{cond} label
	@ins[3..$#ins] = translate(@ins[3..$#ins]);
	#            If it's a label            Use the label   or if it's a number use that   Otherwise die
	my $target = exists($labels{lc $ins[3]}) ? $labels{lc $ins[3]} : isnum($ins[3]) ? $ins[3] :
	  throw("Error parsing branch. Could not find plausable destination for $ins[3].");

	if ( $target ) {
	    vprint "Branching to instruction $target label $ins[3]\n";
	    if ( $ins[0] eq 'BL' ) {
		$reg[14]=$reg[15]-4; # PC+8-8+4
		vprint "Link: Return to instruction $reg[14]\n";
	    }
	    $reg[15]=$target;
	    modreg(15);
	}
	else { throw("Error parsing branch. No label $ins[3]") }
    }
    elsif ( $ins[0] eq 'MOV' ) { # MOV{cond}{S} Rd, <Operand2>
	#throw("S flag unsupported due to unknown function") if $ins[2] eq 'S';
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = $ins[4];
	    vprint "Placing $ins[4] in R$reg\n";
	    logicalsflags(1,$ins[4]) if $ins[2] eq 'S';
	    modreg($reg);
	}
	else { throw("Non-register target for MOV $reg[15]") }
    }
    elsif ( $ins[0] eq 'ADD' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armadd($ins[4],$ins[5],0,$S);
	    vprint "Placing $ins[4]+$ins[5]=$reg[$reg] in R$reg\n";
	    modreg($reg);
	}
	else { throw("Non-register target for ADD $reg[15]") }
    }
    elsif ( $ins[0] eq 'ADC' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armadd($ins[4],$ins[5],$C?1:0,$S);
	    vprint "Placing $ins[4]+$ins[5]=$reg[$reg] in R$reg\n";
	    modreg($reg);
	}
	else { throw("Non-register target for ADC $reg[15]") }
    }
    elsif ( $ins[0] eq 'SUB' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armsub($ins[4],$ins[5],1,$S);
	    vprint "Placing $ins[4]-$ins[5]=$reg[$reg] in R$reg\n";
	    modreg($reg);
	}
	else { throw("Non-register target for SUB $reg[15]") }
    }
    elsif ( $ins[0] eq 'SBC' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armsub($ins[4],$ins[5],0,$S);
	    vprint "Placing $ins[4]-$ins[5]=$reg[$reg] in R$reg\n";
	    modreg($reg);
	}
	else { throw("Non-register target for SUB $reg[15]") }
    }
    elsif ( $ins[0] eq 'CMP' or $ins[0] eq 'CMN' ) {
	@ins[3..$#ins] = translate(@ins[3..$#ins]);

	if ( $ins[0] eq 'CMP' ) { armsub($ins[3],$ins[4],1,1) } #CI,S
	elsif ( $ins[0] eq 'CMN' ) { armadd($ins[3],$ins[4],0,1) } #CI,S
    }
    elsif ( $ins[0] eq 'LDR' ) {
	my $isaddr = 0;
	if ( $ins[4] =~ /[a-z]/i && $ins[4] =~ /^(=?)(\w+)$/ ) {
	    # Eligible to be a label
	    $isaddr = $1;
	    my $one = $2;
	    if ( exists($labels{lc $one}) && $labels{lc $one}=~ /^(\d+)\|(\d+)$/ ) {
		# Is a label
		vprint "Translating $ins[4] for LDR\n";
		$ins[4] = $1;
		$B = $2;
		vprint "Result=$ins[4]\tB=$B\n";
	    }
	}

	@ins[4..$#ins] = translate(@ins[4..$#ins]) unless $isaddr; # 3 is destination
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = $isaddr?$ins[4]:getmem($ins[4],$B?1:0);
	    vprint("Placing ".($B?'(byte) ':'')."$reg[$reg] in R$reg\n");
	    modreg($reg);
	}
	else { throw("Non-register target for LDR $reg[15]") }
    }
    elsif ( $ins[0] eq 'EOR' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armxor($ins[4],$ins[5],$S);
	    vprint "Placing $ins[4]^$ins[5]=$reg[$reg] in R$reg\n";
	    modreg($reg);
	}
	else { throw("Non-register target for ADD $reg[15]") }
    }
    elsif ( $ins[0] eq 'AND' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armand($ins[4],$ins[5],$S);
	    vprint "Placing $ins[4]&$ins[5]=$reg[$reg] in R$reg\n";
	    modreg($reg);
	}
	else { throw("Non-register target for ADD $reg[15]") }
    }
    elsif ( $ins[0] eq 'ORR' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armor($ins[4],$ins[5],$S);
	    vprint "Placing $ins[4]|$ins[5]=$reg[$reg] in R$reg\n";
	    modreg($reg);
	}
	else { throw("Non-register target for ADD $reg[15]") }
    }
    elsif ( $ins[0] eq 'STR' ) {
	my $isaddr = 0;
	if ( $ins[4] =~ /[a-z]/i && $ins[4] =~ /^(=?)(\w+)$/ ) {
	    # Eligible to be a label
	    $isaddr = $1;
	    my $one = $2;
	    if ( exists($labels{lc $one}) && $labels{lc $one}=~ /^(\d+)\|(\d+)$/ ) {
		# Is a label
		vprint "Translating $ins[4] for STR\n";
		$ins[4] = $1;
		$B = $2;
		vprint "Result=$ins[4]\tB=$B\n";
	    }
	}
	die("Can't store address") if $isaddr;
	@ins[3..$#ins] = translate(@ins[3..$#ins]); # 4 is destination

	setmem($ins[4],$ins[3],$B?1:0);
	vprint("Placing ".($B?'(byte) ':'')."$ins[3] in memory at $ins[4]\n");
    }
    elsif ( $ins[0] eq 'NOOP' ) { # Nonstandard instruction
	vprint "No Op\n";
    }
    elsif ( $ins[0] eq 'DIE' ) { # Nonstandard instruction
	if ( $d ) {
	    $died = "Program died at $line";
	    $debugnext = 1;
	    next;
	}
	else {
	    throw("Program died at $line");
	}
    }
    elsif ( $ins[0] eq 'END' ) { last } # Nonstandard instruction
    elsif ( $ins[0] eq 'OUT' ) { # Nonstandard instruction
	my @oldins = @ins;
	@ins[3..$#ins] = translate(@ins[3..$#ins]);
	for ( my $i=3;$i<= $#ins;$i++ ) {
	    if ( $S ) {
		printf "$oldins[$i] = 0x%08x\n",$ins[$i];
	    }
	    elsif ( $B ) {
		my $str = pack('N',$ins[$i]);
		$str =~ s/^\0+(.+)$/$1/;
		printf "$oldins[$i] = \"%s\"\n",$str;
	    }
	    else {
		print "$oldins[$i] = $ins[$i]\n";
	    }
	}
    }
    elsif ( $ins[0] eq 'SWI' ) { # SWIs are not supported.
	throw("SWI is not supported. Complain if you think I need it.");
    }
    else {
	# Undefined instruction.
	throw("Undefined instruction at $line");
    }

    $reg[15]+=4;			# Next instruction
}
print "Program complete.\n";

sub throw {
    my ($msg) = @_;
    die $msg;
}

sub isnum {
    return shift(@_) =~ /^\d+$/;
}

sub isreg {
    my ($pos) = @_;
    $pos = uc $pos;
    vprint "TODO: R15 only contains PC. See http://www.heyrick.co.uk/assembler/psr.html\n" if $pos eq 'PC' or $pos eq 'R15';
    return 15 if $pos eq 'PC';
    return 14 if $pos eq 'LR';
    if ( $pos =~ /^R(\d+)$/ ) {
	return undef unless $1 >= 0 && $1<=15;
	return $1;#wantarray ? [1,$reg[$1]] : 1;
    }
    return undef;
}
sub translate {
    my @args = @_;
    foreach ( @args ) {
	my $offset = 0;
	$_ =~ s/^\[(.+)\]$/$1/; # Address
	# =Label => [PC,#offset]
	my $offsetshift = 0;
	if ( $_ =~ s/,\s*(.+)$// ) { # If there is a FOP
	    my $fop = $1;
	    vprint "FOP: $1\n";
	    if ( $fop =~ /^([#&](-?[\da-fx]+)|R\d+|PC)$/i ) { # Numbers
		# If it is a number or register, you add that to the
		# result
		$offset = translate($1);
	    }
	    elsif ( $fop =~ /^($fopmatch)\s+(R\d+|[#&][0-9a-fx]+)$/i ) {
		my $fopkind = uc $1;
		my $fopby = translate($2);

		# Rotational and shifting FOPs
		if ( $fopkind eq 'LSL' ) { # Logical Left
		    $offsetshift = -1;
		    $offset = $fopby;
		    #$_ = $_ << $fopby;
		}
		elsif ( $fopkind eq 'LSR' ) { #Logical Right
		    $offsetshift = 1;
		    $offset = $fopby;
		    #$_ = $_ >> $fopby;
		}
		elsif ( $fopkind eq 'ASR' ) { # Arithmetic Right
		    # $a & 0x80000000 to get high bit then shift then or
		    $offsetshift = 2;
		    $offset = $fopby;
		}
		elsif ( $fopkind eq 'ROR' ) { # Rotate Right
		    $offsetshift = 3;
		    $offset = $fopby;
		}
		#print "FOP $fopkind by $fopby\n";
	    }
	    else { throw("Bad FOP - got through the parser but not the translator? $fop") }
	}
	print "TODO: R15 only contains PC. See http://www.heyrick.co.uk/assembler/psr.html\n" if $_ eq 'PC' or $_ eq 'R15';

	if ( uc $_ eq 'PC' ) { $_ = $reg[15] } # PC is R15
	elsif ( $_ =~ /^R(\d+)$/i ) {
	    throw("$_ is not in range 0-15") unless $1 >= 0 && $1<=15;
	    $reg[$1]||=0; # We have a value
	    vprint "Translating $_ to $reg[$1]\n";

	    if ( !$offset ) { $_ = $reg[$1] }
	    elsif ( $offsetshift == 0 ) { # Offset of number or register
		$_ = $reg[$1] + $offset;
		vprint "   (plus FOP Offset $offset equals $_)\n";
	    }
	    elsif ( $offsetshift == -1 ) { # LSL
		my $carrymask = 1 << (32-$offset);
		$fopco = $reg[$1]&$carrymask ?1:0;

		$_ = $reg[$1] << $offset;
		vprint "   (But shifted left $offset equals $_)\n";
	    }
	    elsif ( $offsetshift == 1 ) { # LSR
		my $carrymask = 1 << ($offset-1);
		$fopco = $reg[$1]&$carrymask ?1:0;

		$_ = $reg[$1] >> $offset;
		vprint "   (But shifted right $offset equals $_)\n";
	    }
	    elsif ( $offsetshift == 2 ) { # ASR
		my $carrymask = 1 << ($offset-1);
		$fopco = $reg[$1]&$carrymask ?1:0;
		my $highbit = $reg[$1] & 0x80000000;
		$_ = ($reg[$1] >> $offset);
		if ( $highbit ) {
		    my $highmask = $offset == 32 ? 0xFFFFFFFF : ((1<<$offset)-1)<<(32-$offset);
		    $_ |= $highmask;
		}
		vprint "   (But shifted right $offset and high-bitized equals $_)\n";
	    }
	    elsif ( $offsetshift == 3 ) { # ROR
		my $carrymask = 1 << ($offset-1);
		$fopco = $reg[$1]&$carrymask ?1:0;

		my $mask = ((1<<$offset)-1);
		my $lowbits = ($reg[$1]&$mask)<<(32-$offset);
		$_ = ($reg[$1]>>$offset)|$lowbits;
		vprint "   (But rotated right $offset equals $_)\n";
	    }
	}
	elsif ( $_ =~ /^#(-?\d+)$/ ) { # Numbers
	    $_ = $1+0;
	}
	elsif ( $_ =~ /^(?:&|#0x)(-?[\dA-F]+)$/i ) { # Hex Numbers (?)
	    $_ = hex($1);
	}
	elsif ( $_ =~ /^(=?)(\w+)$/i ) { # Addresses
	    if ( $1 ) { # Get the address (=Label)
		$_ = exists($labels{lc $2}) && $labels{lc $2}=~ /^(\d+)\|(\d+)$/?$1:$_;
	    }
	    else { # Memory
		my $ol = $_;
		$_ = exists($labels{lc $2}) # If the label exists
		  && $labels{lc $2}=~ /^(\d+)\|(\d+)$/ # And is (was?) a DCx
		    ?getmem($1,$2) # Load memory
		      :$_; # Otherwise, if something isn't right, leave it.
		vprint "Translating $ol to $_\n";
	    }
	}
	if ( $_ =~ /^\d+$/ ) { $_+=0 } # Numberize numbers
	# Let someone else deal with it.
    }
    return @args;
}

sub armsub {
    my ($a,$b,$ci,$s) = @_;
    $b += 0;
    return armadd($a,~$b,$ci,$s);
}

sub armadd {
    my ($a,$b,$ci,$s) = @_;
    $ci = $ci?1:0;
    my $result = $a+$b+$ci;
    if ( $s ) {
	vprint "Setting S flags\n";
	#my $ci=(($a & 0x7FFFFFFF)+($b & 0x7FFFFFFF)) & 0x80000000;
	my $cis=((($a & 0x7FFFFFFF)+($b & 0x7FFFFFFF)+$ci) & 0x80000000) ?1:0;
	my $hba = ($a & 0x80000000)?1:0;
	my $hbb = ($b & 0x80000000)?1:0;

	$N = $result & 0x80000000 ? 1:0;
	$Z = $result == 0         ? 1:0;
	$C = $cis+$hba+$hbb>=2     ? 1:0;
	$V = ($C xor $cis)||0;
	vprint "CI: $cis\tN: $N\tZ: $Z\tC: $C\tV: $V\n";
    }
    return $result;
}

sub armxor {
    my ($a,$b,$s) = @_;
    my $result = $a^$b;
    logicalsflags($s,$result);
    return $result;
}

sub armand {
    my ($a,$b,$s) = @_;
    my $result = $a&$b;
    logicalsflags($s,$result);
    return $result;
}

sub armor {
    my ($a,$b,$s) = @_;
    my $result = $a|$b;
    logicalsflags($s,$result);
    return $result;
}

sub logicalsflags {
    my ($s,$result) = @_;
    if ( $s ) {
	vprint "Setting S flags\n";
	#my $ci=(($a & 0x7FFFFFFF)+($b & 0x7FFFFFFF)) & 0x80000000;
	#my $hba = ($a & 0x80000000)?1:0;
	#my $hbb = ($b & 0x80000000)?1:0;

	$N = $result & 0x80000000 ? 1:0;
	$Z = $result == 0         ? 1:0;
	$C = $fopco; # Use rotational or shifting FOP Carry Out.
	#$V = 0;
	vprint "CI: N/A\tN: $N\tZ: $Z\tC: $C\tV: N/A\n";
    }
}

#sub armcmp {
#    my $result = $ins[3]+~$ins[4]+1;#$ins[3]-$ins[4];
#    printf "0x%x+0x%x+0x1=0x%x\n",$ins[3],~$ins[4],$result;
#    print "Subtracting ($result)...\n";
#}

sub getmem {
    my ($index,$byteonly) = @_;
    $memory .= chr(0)x($index-length($memory)+8)
      if length($memory)-$index < 0;
    if ($byteonly ) { return ord(substr($memory,$index,1)) }
    else { return unpack('N',substr($memory,$index,4)) } # See $memory comment
}

sub setmem {
    my ($index,$content,$byteonly) = @_;
    $memory .= chr(0)x($index-length($memory)+4+8)
      if length($memory)-$index < 0;
    if ($byteonly ) { return substr($memory,$index,1,chr($content)) }
    else { return substr($memory,$index,4,pack('N',$content)) }
}

sub MungeString {
    my ($tmp) = @_;
    vprint "Munging string $tmp\n";
    $tmp =~ s/\\\\/\\/g;
    my $out = '';
    foreach(split('',$tmp)) {
	$out.='#'.ord($_).', ';
    }
    $out =~ s/\,\s*$//g;
    vprint "  $out\n";
    return $out;
}

sub modreg {				# Do any special things that need to
    my ($reg) = @_;			# be done when a register has been
    if ( $reg == 15 ) {			# modified
	$reg[15]+=4;
    }
}
