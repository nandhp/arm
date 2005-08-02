#!/usr/bin/perl
#
# Perl ARM Simulator
#
# Copyright (c) 2005 nandhp. Licensed under the GNU GPL.
# http://www.gnu.org/copyleft/gpl.html
#

use strict;
use warnings;
use integer;
use Getopt::Long qw(:config gnu_getopt);
use Pod::Usage;
use Term::ReadLine;

my $VERSION='20050802';# yyyymmdd

$| = 1;

my $v = 0;
my $help = 0;
my $man = 0;
my $q = 0;
my $d = 0;
my $o = '';
my ($mode,$mode_a,$mode_d,$mode_x) = (0,0,0,0);

GetOptions('debug|d' => \$d, 'verbose|v' => \$v, 'quiet|q' => \$q, 'output|o=s' => \$o, 'help|h|?' => \$help, 'assemble|a' => \$mode_a, 'disassemble|D' => \$mode_d, 'execute|x' => \$mode_x, 'man' => \$man, 'version' => \&show_version) or show_help();
show_help(1) if $help;
show_help(2) if $man;

my $term = new Term::ReadLine 'ARM Debugger';
my $prompt = '<DB> ';
my $OUT = \*STDOUT;
my $debugnext = 1; # Stop at next statement
my $defaultc = 0;

if ( !$mode_a && !$mode_d && !$mode_x ) {
    if ( scalar(@ARGV) != 1 ) {		# Assume anything but one parameter
	$mode_a = 1;			# should be assembled
    }
    elsif ( $ARGV[0] eq '-' ) {
	$mode_a = 1;
    }
    else {				# File not found, File contents
	open TEST, $ARGV[0] or throw("Can't open $ARGV[0]: $!");
	my $line = <TEST>; # If the first line has
	if ( $line =~ /^#!/ ) { $mode_a = 1 } # a shebang,
	elsif ( $line =~ /^;/ ) { $mode_a = 1 } # a comment,
	elsif ( $line =~ /^[\sa-zA-Z;]{3}/ ) { $mode_a = 1 }
	# or something similar to an indented assembler instruction, then
	# Assemble it.
	else { $mode_x = 1 } # If not, execute it.
	close TEST;
    }
    # if ( $mode_a && !$o ) { $mode_x = 1 } # If no -o, execute as well.
}

if ( $mode_a ) {
    $mode = 1;
    #$v = 0;
}
elsif ( $mode_d ) {
    $mode = 2;
}
elsif ( $mode_x ) {
    $mode = 3;
}
else {
}

if ( $d && $mode == 3 ) {
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

    die "The dubugger is currently broken" if $d;
}
elsif ( $d ) {
    show_help(1,"Option --debug is only available during execution.\n");
    #print "Assembling with debug information...\n";
}

$v = -1 if $q;

=head1 NAME

arm.pl - Interpret ARM Assembler in Perl

=head1 SYNOPSIS

arm.pl [options] [file ...]

=head1 OPTIONS

=over

=item B<--assemble>, B<--disassemble>, B<--execute>

Set the operating mode. Since the appropriate operating mode is
usually automatically detected, these options should rarely be
needed. See the section on MODES OF OPERATION in the documentation.

=item B<--output>, B<-o> I<filename>

In assembly mode, specifies the output file for the assembled machine
code.

In disassembly mode, specifies the output file for the disassembled
assembler code. If not given, defaults to STDOUT.

=item B<--debug>, B<-d>

Run the provided assembler code under the debugger. The debugger is
currently broken.

=item B<--quiet>, B<-q>

Be quiet. This will cause the default behavior, to output each
instruction as it is executed, to be turned off. This switch is
ignored when B<--debug> is specified.

=item B<--verbose>, B<-v>

Be verbose -- more verbose then the default -- about parsing,
compilation and execution. If the default verbosity is too verbose and
you want to tone it down, try B<--quiet>.

=item B<--version>

Display the arm.pl version number and check for updates.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Display the full documentation, for which you may want to use a pager.

=back

=head1 DESCRIPTION

B<arm.pl> will parse the given input file(s) as either ARM Assembler
code or ARM machine code as described below.

=head1 MODES OF OPERATION

B<arm.pl> has three modes of operation.

=over

=item B<ASSEMBLE> (B<--assemble>, B<-a>)

Treat the input file as ARM Assembler code, and assemble it to the
file given with the B<--output> option. You may provide options B<-a>
and B<-x> together to assemble and execute without saving the
assembled machine code.

=item B<DISASSEMBLE> (B<--disassemble>, B<-D>)

Treat the input file as ARM Machine code, and disassemble it into some
poor but (with the exception of branch) working ARM Assembler
code. Use B<--output> to put it into a file.

=item B<EXECUTION> (B<--execute>, B<-x>)

Treat the input file as ARM Machine code, and execute it.

=back

When none of these options are provided, arm.pl will examine the file
to determine whether it is best to assemble or execute it.

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

L<http://nand.homelinux.com:8888/~nand/blosxom/>

=back

=head1 BUGS

None

=head1 AUTHOR

nandhp <nandhp AT myrealbox WITHNOSPAM com>

=cut

sub show_version {
    print "arm.pl version $VERSION\n\nChecking for updates...";
    my @vup = split("\n",eval('use LWP::Simple;return get("http://nand.homelinux.com:8888/~nand/blosxom/update/au_check.cgi")')||'');
    print "\n\n";
    if ( !@vup ) {
	print "There was an error checking for updates.\nPlease try back later.\n";
    }
    elsif ( $vup[0] < $VERSION ) {
	print "You are running an as-yet unreleased version.\nThere are no updates available.\n";
    }
    elsif ( $vup[0] == $VERSION ) {
	print "You are running the latest version.\nThere are no updates available.\n";
    }
    elsif ( $vup[0] > $VERSION ) {
	print "The latest version is $vup[0].\n";
	if ( -f 'update.pl' && eval 'use Tk;1' ) {
	    print "Starting ARM Simulator Update...\n";
	    if ( $^O eq 'MSWin32' ) { system 'start perl update.pl' }
	    else { system 'perl update.pl&' }
	}
	else {
	    print "For more information on this version, visit\n$vup[1]\n";
	}
    }
    exit(1);
}

sub show_help {
    my ($arg,$msg) = @_;
    $arg ||= 0;
    if ( $msg ) {
	pod2usage(-verbose => $arg,-msg => $msg);
    }
    elsif ( $arg == 0 ) {
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

sub vprint($)   { print  @_ if $v >= 1 }
sub vvprint($)  { print  @_ if $v >= 2 }
sub vprintf     { printf @_ if $v >= 1 }
sub vvprintf    { printf @_ if $v >= 2 }

my %conds = (
	     EQ => '0000',# Equal: If the Z flag is set after a comparison.
	     NE => '0001',# Not equal: If Z flag is clear after a comparison.
	     CS => '0010',# Carry Set: Set if the C flag is set after an
                          # arithmetical operation OR a shift operation,
                          # the result of which cannot be represented in
                          # 32bits. You can think of the C flag as the 33rd
                          # bit of the result.
 	     HS => '0010',# Unsigned higher or same (i.e. CS)
	     CC => '0011',# Carry Clear: The reverse of CS.
	     LO => '0011',# Unsigned lower (i.e. CC)
	     MI => '0100',# Negative: If the N flag set after an arithmetic op.
	     PL => '0101',# Positive or zero: If the N flag is clear after
                          # an arithmetical operation. For the purposes of
                          # defining 'plus', zero is positive because it
                          # isn't negative...
	     VS => '0110',# Overflow: If V flag set after arithmetic op,
                          # the result of which won't fit into a 32bit dest reg
	     VC => '0111',# No overflow: If V flag is clear, reverse of VS.
	     HI => '1000',# Unsigned higher: If after a comparison the C
                          # flag is set AND the Z flag is clear.
	     LS => '1001',# Unsigned lower or same: If after a comparison
                          # the C flag is clear OR the Z flag is set.
	     GE => '1010',# Signed greater than or equal: If after comparison..
	                  # the N flag is set AND the V flag is set
	                  # or...
	                  # the N flag is clear AND the V flag is clear.
	     LT => '1011',# Signed less than: If after a comparison...
	                  # the N flag is set AND the V flag is clear
	                  # or...
	                  # the N flag is clear AND the V flag is set.
	     GT => '1100',# Signed greater than: If after a comparison...
	                  # the N flag is set AND the V flag is set
	                  # or...
	                  # the N flag is clear AND the V flag is clear
	                  # and...
	                  # the Z flag is clear.
	     LE => '1101',# Signed less than or equal: If after a comparison...
	                  # the N flag is set AND the V flag is clear
	                  # or...
	                  # the N flag is clear AND the V flag is set
	                  # and...
	                  # the Z flag is set.
	     AL => '1110',# Always (normally omitted)
	     NV => '1111',# Never (do not use, see Architecture Manual pg A3-5)
	    );

# This will probably house opcodes at some point.

my %instructions = (
		    # Unimplemented instructions
		    LDM => '-99999',
		    STM => '-99999',
		    BIC => '1110',
		    TEQ => '1001',
		    TST => '1000',
		    MSR => '-99999',
		    MRS => '-99999',
		    MVN => '1111',
		    MLA => '-99999',
		    MUL => '-99999',
		    RSC => '0111',
		    RSB => '0011',

		    # Implemented instructions
		    B   => '-1',
		    BL  => '-1',
		    MOV => '1101',
		    SUB => '0010',
		    CMP => '1010',
		    ADD => '0100',
		    SWI => '-4',
		    EOR => '0001',
		    # Beta instructions
		    LDR => '-2',
		    STR => '-2',
		    # Alpha instructions
		    CMN => '1011',
		    ADC => '0101',
		    SBC => '0110',
		    ORR => '1100',
		    AND => '0000',

		    # Nonstandard instructions
		    ADR => '-3',
		    NOP => '-3',
		    DIE => '-3',
		    END => '-3',
		    OUT => '-3',
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
my @mempos = ();
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

my $condmatch = join('|',keys %conds);
my $insmatch = join('|',keys %instructions);
my $xmatch = join('|',keys %extra);
my $fopmatch = join('|',keys %operand_flags);

my $insnum = 0;
my $mempos = 0;
my $includefn = scalar(@ARGV)>1?1:0;
my $lastlabel='';

goto disassemble if $mode > 1;		# I know that GOTO is bad, but I did
                                        # not want to have to indent all of
                                        # the next 300 lines.

# Process the program
print "Parsing source...\n" if $v >= 0;

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
	my $bdw = uc $1;
	my $vals = $2;
	vprint "Processing DC$1...\n";
	if ( $bdw eq 'D' ) {		# Define Constant Data doesn't act
	    $bdw = 'W';			# constant here... See ARMBook p29
	}

	# A quote followed by a bunch of stuff and then another quote
	# that is not preceeded by a backslash.
	$vals =~ s/\"(.+?)(?<!\\)\"/MungeString($1)/ge;
	if ( $bdw eq 'B' ) {
	    $labels{$lastlabel}="$mempos|1";
	    foreach ( split ',', $vals ) {
		s/^\s*|\s*$//g;
		setmem($mempos,isimmed($_)||0,1);
		vprint "$_ stored at $mempos (size 1) label $lastlabel=$labels{$lastlabel}\n";
		push @mempos, -1;
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
		setmem($mempos,isimmed($_)||0,0);
		vprint "$_ stored at $mempos (size 4) label $lastlabel=$labels{$lastlabel}\n";
		push @mempos, -4;
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
    # Here there be dragons and flexible operands
    while ( $params =~ /\s*([\-\+A-Z0-9#&x]+\s*(,\s*($fopmatch).*)?|\[R\d+(,\s*($fopmatch)?\s*(?:#[+-]?\d+|R\d+|PC))?\]|=?\w+)\s*(,\s*|$)/gi ) {
	push @params, $1;
	vprint "Param: $1\n";
    }
    my @instruction = ($ins,$cond,$extra);
    push @instruction, @params;
    push @program, \@instruction;
    push @mempos, $mempos;
    $lines[$mempos/4] = $includefn?"$ARGV:$.":"$.";
    # TODO: Remove below comment
    # # TODO: Use real instruction representations
    setmem($mempos,$insnum,0);
    $mempos+=4;

    $insnum++;
    vprint "\n";
}
continue { close ARGV if eof }		# To reset $.
  ;

push @program, 0;			# Last instruction should be 0 - See branch
push @mempos, undef;

# Produce machine code. This should be interesting.
print "Assembling...\n" if $v >= 0;

# Notes: SBZ = Should Be Zero
$mempos = 0;
my $progi=0;

my $OUTPUT = undef;
if ( $o ) {
    open $OUTPUT, '>',$o or die "Can't open output file: $!";
    binmode $OUTPUT;
}
my $newmem = '';

my $skip_to_mempos = -1;
foreach my $item ( @mempos ) {
    last unless defined($item);
    ($mempos++,next) if $mempos<$skip_to_mempos;
    my $out = '';

    my $mps = sprintf '%d', $mempos;
    $mps .= ' 'x(4-length($mps));

    if ( $item =~ /^(-\d+)$/ ) { # DCx needs to be dumped too!
	if ( $item eq '-4' ) {
	    my $tmp = getmem($mempos,0)||0;#,pack('V',$tmp);
	    printf "%s %032b   %08X  DATA  4 BYTES\n",$mps,$tmp,$tmp
	      if $v >= 1;
	    $out = pack('V',$tmp);
	    $mempos+=4;
	}
	elsif ( $item eq '-1' ) {
	    my $tmp = getmem($mempos,0)||0;
	    printf "%s %032b   %08X  DATA  4x 1 BYTE\n",$mps,$tmp,$tmp
	      if $v >= 1;
	    $out = pack('V',$tmp);
	    $skip_to_mempos=$mempos+4;
	    $mempos++;
	}
	else {
	    print $mps.' '.'!'x32, ' 'x(8+2+1), "  DATA  ? BYTES\n" if $v >= 0;
	}

	print $OUTPUT $out if $OUTPUT;
	$newmem .= $out if $mode_x;
	next;
    }

    my @ins = @{$program[$progi]};
    my $opcode = $instructions{$ins[0]};

    # Instruction conversions
    #
    # CMP and CMN always have the S bit set
    # NOP becomes MOVNV R0, R0

    $ins[2] = 'S' if $opcode eq '1010' or $opcode eq '1011'; # CMP and CMN

    if ( $ins[0] eq 'NOP' ) {     # NOP hack - Turn NOP into a MOVNV R0,R0
	$ins[1] = 'AL'; $ins[0] = 'MOV'; $ins[2] = ''; $ins[3] = 'R0';
	$ins[4] = 'R0';
	$opcode = $instructions{$ins[0]};
    }

    if (
	($ins[0] eq 'LDR' and $ins[4] =~ /^=(\w+)$/) or
	($ins[0] eq 'ADR' and $ins[4] =~ /^(\w+)$/)
       ) {
	$opcode = '0100';
	$ins[0] = 'ADD';
	$ins[2] = '';
	$ins[4] = 'R15';
	if ( exists($labels{lc $1}) ) {
	     $labels{lc $1} =~ /^(\d+)\|(\d+)$/;
	     $ins[5] = '#'.($1-$mempos-8);
	}
	else {
	    throw("Invalid LDR=label");
	}
    }
    # Begin assembling the instruction. Start with the conditional.

    $out .= $conds{$ins[1]};		# Conditional		31-28

    # Then continue with the instruction-specific part.
    if ( $opcode >= 0000 ) {    # Data Processing Instructions
	my $rn='0000'; # Stays 0000 for MOV and MVN
	my $rd='0000'; # Stays 0000 for TST, TEQ, CMP and CMN
	my @operand = ();
	if ( $opcode eq '1101' or $opcode eq '1111' ) { #MOV and MVN
	    my $isreg = isreg($ins[3]);
	    $rd = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rd must be register on instruction $mempos");

	    @operand = parse_operand2($ins[4]);
	}
	elsif ( $opcode eq '1000' or $opcode eq '1001' # TST, TEQ
		or $opcode eq '1010' or $opcode eq '1011' ) { # CMP, CMN
	    my $isreg = isreg($ins[3]);
	    $rn = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rn must be register on instruction $mempos");

	    @operand = parse_operand2($ins[4]);
	}
	else { # All other instructions
	    my $isreg = isreg($ins[3]);
	    $rd = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rd must be register on instruction $mempos");

	    $isreg = isreg($ins[4]);
	    $rn = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rn must be register on instruction $mempos");

	    @operand = parse_operand2($ins[5]);
	}
	$out .= '00';			# Bits			27-26
	$out .= shift @operand;		# I bit			25
	$out .= $opcode;		# opcode		24-21
	$out .= $ins[2] eq 'S'?1:0;	# S bit			20
	$out .= $rn;			# Rn (src1)		19-16
	$out .= $rd;			# Rd (dest)		15-12
	$out .= shift @operand;		# shifter_operand	11-0
    }
    elsif ( $opcode eq '-1' ) { # Branch (with Link)
	$out .= '101';			# Bits			27-25
	$out .= $ins[0] eq 'BL'?1:0;	# L			24
	$out .= ' ';
	if ( !exists($labels{lc $ins[3]}) ) { throw("\n\nNo label $ins[3]") }
	$out .= dec2bin(($labels{lc $ins[3]}-($mempos+8))>>2,24);#+-24-bit offset 23-0
    }
    elsif ( $opcode eq '-2' ) { # LDR and STR
	my @operand;
	if ( exists($labels{lc $ins[4]}) ) {
	    $labels{lc $ins[4]} =~ /^(\d+)/;
	    @operand = parse_operand2('[R15, #'.($1-$mempos-8).']');
	}
	else {
	    @operand = parse_operand2($ins[4]);
	}
	my ($I,$P,$U,$W,$Rn,$operand) = @operand;
	if ( scalar @operand < 6 ) { ($I,$P,$U,$W,$Rn,$operand) =
	      ('?','?','?','?','R0','????????????') }

	$out .= '01';			# Bits			27-26
	$out .= $I||'0';		# I bit			25
	$out .= $P||'0';		# P bit			24
	$out .= $U||'0';		# U bit			23
	$out .= $ins[2]=~/B/?1:0;	# B bit			22
	$out .= $W||'0';		# W bit			21
	$out .= $ins[0] eq 'LDR'?1:0;	# L bit			20
	$out .= ' ';
	$out .= dec2bin(isreg($Rn),4);	# Rn 			19-16
	#$out .= ' ';
	$out .= dec2bin(isreg($ins[3]),4);# Rd (dest)		15-12
	#$out .= ' ';
	$out .= $operand;		# addr_mode_specific	11-0
    }
    elsif ( $opcode eq '-3' ) { # arm.pl nonstandard Instructions
	# OUT, OUTS, OUTB, END, DIE
	#
	# See docs/nonstandard.txt for more information on arm.pl's
	# use of the undefined instruction set

	$out .= '011';			# Bits			27-25
	$out .= '11111';		# Bits			24-20
	if ( $ins[0] eq 'OUT' ) {
	    if ( $ins[2] eq 'S' ) { $out .= '0001' }
	    elsif ( $ins[2] eq 'B' ) { $out .= '0010' }
	    elsif ( defined(isimmed($ins[3])) ) { $out .= '0011' }
	    else { $out .= '0000' }
	    $out .= ' ';
	    if ( defined(isreg($ins[3])) ) {
		$out .= dec2bin(isreg($ins[3]),4);# Register
		$out .= '000011110000';
		# $out .= dec2bin(isreg($ins[4])||0,4);# Register
		# $out .= '1111';		# Bits
		# $out .= dec2bin(isreg($ins[5])||0,4);# Register
	    }
	    elsif ( defined(isimmed($ins[3])) ) {
		$out .= dec2bin(isimmed($ins[3]),8);
		$out .= '1111'.'0000';	# Bits, last four bits
	    }
	    else {
		throw("OUT: Parse error");
	    }
	}
	elsif ( $ins[0] eq 'END' or $ins[0] eq 'DIE' ) {
	    $out .= $ins[0] eq 'END'?'0100 ':'0101 '; # Opcode
	    $out .= '0000'x2;		# SBZ x 2
	    $out .= '1111';		# Bits			7-4
	    $out .= '0000';		# SBZ			3-0
	}
    }
    elsif ( $opcode eq '-4' ) { # SWI
	$out .= '1111';			# Bits			27-24
	$out .= ' ';
	$out .= dec2bin(isimmed($ins[3]),24);# immed_24		23-0
    }
    else {
	$out .= '!'x28;
	$out .= ' ';
    }
    print $mps.' '.$out,'  ', bin2hex($out), '  ',
      join(' ',@ins[0..2]),' ',join(', ',@ins[3..$#ins]),"\n" if $v >= 1;

    my $asm = bin2chars($out);
    print $OUTPUT $asm if $OUTPUT;
    $newmem .= $asm if $mode_x;

    $mempos+=4;
    $progi++;
}
if ( $OUTPUT ) {
    # chmod +x ...no seriously.
    my $x=sprintf("%o", (stat $o)[2]);
    $x =~ tr/64/75/;
    $x =~ s/^.*(0[0-7]{3})$/$1/;
    chmod eval $x,$o;

}
elsif ( $mode_x ) {
    $memory = $newmem;
    undef $newmem;
    vprint "\n\n\n";
    goto execute;
}

exit(0); # That's the end of the assembly line.

disassemble:

$mempos = 0;
foreach ( @ARGV ) {
    open INPUT, $_  or throw("Can't open $_: $!");
    binmode INPUT;
    while ( read INPUT, $memory, 4, $mempos ) { $mempos+= 4 }
    close INPUT;
}

execute:

# Run it
my ($N,$Z,$C,$V) = (0,0,0,0);
my $S = 0;
my $B = 0;

my $fopco = 0;
my $unknownid = 0;

my @reg = ();
$reg[$_] = 0 foreach 0..15;
if ( $mode == 2 ) {
    print STDERR "Beginning disassembly\n" if $v >= 0;
    if ( $o ) {
	open DIO, ">$o" or die "Can't open output file: $!";
    }
    else {
	*DIO = *STDOUT;
    }
}
else {
    print "Begining execution on instruction 0\n" if $v >= 0;
}
$reg[15]=8; # PC, 2 ahead, multiply by four

my $rmeight;
my $died = 0;

INSTRUCTION:
while ( $reg[15]<=length($memory)+4 ) {	# Plus Eight. Sigh.
    my $instruction = getmem($rmeight = $reg[15]-8,0);
    my $binary = dec2bin($instruction,32);

    my %instruction = %{parse_instruction($binary)};

    if ( $mode == 2 and ( $v < 0 or $o ) ) {
	print DIO "\t",disassemble_instruction(\%instruction),"\n";
    }
    if ( $v >= 0 ) {
	my $mps = sprintf '%d', $reg[15]-8;
	$mps .= ' 'x(4-length($mps));
	print $mps," $binary   ",bin2hex($binary);
	print "  ",disassemble_instruction(\%instruction),"\n";
    }

    ($reg[15] += 4, next) if $mode == 2;

    my $lineflags = '';

    my $oldpc = $reg[15]; # Save old PC so if it changes we don't increment



    my @ins; my $line;

###########################################################################
if ( 0 ) { # ARM Debugger #################################################
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
		    my $str = pack('V',$reg[$rid]);
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
} #########################################################################
###########################################################################

    my $cond = armbits($binary,31,4); # Offset 31-0 like in comments, Length

    # Check conditional
    if ( $cond eq '1110' ) { }
    elsif ( $cond eq '1111' ) { $reg[15]+=4; next }
    elsif ( $cond eq '0000' ) { vprint "EQ: Z=$Z\n";
			      ($reg[15]+=4,next) if !$Z } # Skip if NE
    elsif ( $cond eq '0001' ) { vprint "NE: Z=$Z\n";
			      ($reg[15]+=4,next) if $Z }
    elsif ( $cond eq '0010' ) { vprint "CS: C=$C\n";
			      ($reg[15]+=4,next) if !$C }
    elsif ( $cond eq '0011' ) { vprint "CC: C=$C\n";
			      ($reg[15]+=4,next) if $C }
    elsif ( $cond eq '0100' ) { vprint "MI: N=$N\n";
			      ($reg[15]+=4,next) if !$N }
    elsif ( $cond eq '0101' ) { vprint "PL: N=$N\n";
			      ($reg[15]+=4,next) if $N }
    elsif ( $cond eq '0110' ) { vprint "VS: V=$V\n";
			      ($reg[15]+=4,next) if !$V }
    elsif ( $cond eq '0111' ) { vprint "VC: V=$V\n";
			      ($reg[15]+=4,next) if $V }
    elsif ( $cond eq '1000' ) { vprint "HI: C=$C,Z=$Z\n";
			      ($reg[15]+=4,next) if !$C || $Z }
    elsif ( $cond eq '1001' ) { vprint "LS: C=$C,Z=$Z\n";
			      ($reg[15]+=4,next) if $C || !$Z }
    elsif ( $cond eq '1010' ) { vprint "GE: N=$N,V=$V,Z=$Z\n";
			      ($reg[15]+=4,next) if $V != $N }
    elsif ( $cond eq '1011' ) { vprint "LT: N=$N,V=$V,Z=$Z\n";
			      ($reg[15]+=4,next) if $V == $N }
    elsif ( $cond eq '1100' ) { vprint "GT: N=$N,V=$V,Z=$Z\n";
			      ($reg[15]+=4,next) if $V != $N || $Z }
    elsif ( $cond eq '1101' ) { vprint "LE: N=$N,V=$V,Z=$Z\n";
			      ($reg[15]+=4,next) if $V == $N && !$Z }
    else { throw("Unsupported conditional $cond") }

    # EXECUTE
    if ( $instruction{kind} eq 'B' ) { # Branch
	if ( $instruction{link} ) {
	    $reg[14]=$reg[15]-4; # PC+8-8+4
	    modreg(14);
	    vprint "Link: Return to instruction $reg[14]\n";
	}
	$reg[15]+=$instruction{immediate};
	vprint 'Branch: Branching to '.($instruction{immediate}+$reg[15])."\n";
	modreg(15);
    }
    elsif ( $instruction{kind} eq 'DPI' ) { # Data Processing Instructions
	# Operand 2
	my $op2 = $instruction{srcimmed} ?
	  $instruction{source} : $reg[$instruction{source}];
	my $offset = $instruction{offsetreg} ?
	  $reg[$instruction{offset}] : $instruction{offset};

	if ( $instruction{shifttype} == 0 ) { $op2 += $offset }
	elsif ( $instruction{shifttype} == -1 ) { # LSL
	    my $carrymask = 1 << (32-$offset);
	    $fopco = $op2 & $carrymask?1:0;
	    $op2 <<= $offset;
	}
	elsif ( $instruction{shifttype} == 1 ) { # LSR
	    my $carrymask = 1 << ($offset-1);
	    $fopco = $op2 & $carrymask?1:0;
	    $op2 >>= $offset;
	}
	elsif ( $instruction{shifttype} == 2 ) { # ASR
	    my $carrymask = 1 << ($offset-1);
	    $fopco = $op2 & $carrymask?1:0;
	    my $highbit = $op2 & 0x80000000;
	    $op2 >>= $offset;
	    if ( $highbit ) {
		my $highmask = $offset == 32 ? 0xFFFFFFFF : ((1<<$offset)-1)<<(32-$offset);
		$op2 |= $highmask;
	    }
	}
	elsif ( $instruction{shifttype} == 3 ) { # ROR
	    my $carrymask = 1 << ($offset-1);
	    $fopco = $op2 & $carrymask?1:0;
	    my $mask = ((1<<$offset)-1);
	    my $lowbits = ($op2&$mask)<<(32-$offset);
	    $op2 = ($op2 >> $offset)|$lowbits;
	}

	my $opcode = $instruction{opcode};
	my $rn = $instruction{rn};
	my $rd = $instruction{rd};
	my $S = $instruction{sbit};
	if    ( $opcode eq '0000' ) { # AND
	    $reg[$rd] = armand($reg[$rn],$op2,$S);
	    modreg($rd);
	}
	elsif ( $opcode eq '0001' ) { # EOR
	    $reg[$rd] = armxor($reg[$rn],$op2,$S);
	    modreg($rd);
	}
	elsif ( $opcode eq '0010' ) { # SUB
	    $reg[$rd] = armsub($reg[$rn],$op2,1,$S);
	    modreg($rd);
	}
      # elsif ( $opcode eq '0011' ) { # RSB
	elsif ( $opcode eq '0100' ) { # ADD
	    $reg[$rd] = armadd($reg[$rn],$op2,0,$S);
	    modreg($rd);
	}
	elsif ( $opcode eq '0101' ) { # ADC
	    $reg[$rd] = armadd($reg[$rn],$op2,$C?1:0,$S);
	    modreg($rd);
	}
	elsif ( $opcode eq '0110' ) { # SBC
	    $reg[$rd] = armsub($reg[$rn],$op2,0,$S);
	    modreg($rd);
	}
      # elsif ( $opcode eq '0111' ) { # RSC
      # elsif ( $opcode eq '1000' ) { # TST
      # elsif ( $opcode eq '1001' ) { # TEQ
	elsif ( $opcode eq '1010' ) { # CMP
	    armsub($reg[$rn],$op2,1,1)
	}
	elsif ( $opcode eq '1011' ) { # CMN
	    armadd($reg[$rn],$op2,0,1)
	}
	elsif ( $opcode eq '1100' ) { # ORR
	    $reg[$rd] = armor($reg[$rn],$op2,$S);
	    modreg($rd);
	}
	elsif ( $opcode eq '1101' ) { # MOV
	    $reg[$rd] = $op2;
	    modreg($rd);
	}
      # elsif ( $opcode eq '1110' ) { # BIC
      # elsif ( $opcode eq '1111' ) { # MVN
	else {
	    throw("DPI: Unimplemented instruction");
	}
    }
    elsif ( $instruction{kind} eq 'ARMPL' ) {
	if ( $instruction{opcode} eq 'OUT' &&defined($instruction{immediate})){
	    print "$instruction{immediate}\n";
	}
	elsif ( $instruction{opcode} eq 'OUT' ) {
	    my $fmt = $instruction{format};
	    foreach ( $instruction{reg} ) {
		#,$instruction{regb},$instruction{regc}){
		last unless defined($_);
		if ( $fmt eq 'HEX' ) { printf "R%d = 0x%08x\n",$_,$reg[$_] }
		elsif ( $fmt eq 'BYTES' ) {
		    my $str = pack('V',$reg[$_]);
		    $str =~ s/^\0+(.+)$/$1/;
		    printf "R%d = \"%s\"\n",$_,$str;
		}
		else { printf "R%d = %d\n",$_,$reg[$_] }
	    }
	}
	elsif ( $instruction{opcode} eq 'END' ) { last }
	elsif ( $instruction{opcode} eq 'DIE' ) {
	    throw("Died on instruction $reg[15]")
	}
	else {
	    throw("Undefined instruction of type $instruction{kind}");
	}
    }
    elsif ( $instruction{kind} eq 'MEMOR' ) { # LDR/STR
	my $addr = $reg[$instruction{rn}];
	my $myoffset;
	if ( $instruction{offsetimmed} ) { $myoffset = $instruction{offset} }
	# Insert scaled register support here
	else { $myoffset = $reg[$instruction{offset}] }
	$addr += $myoffset*($instruction{positive}?1:-1);

	if ( $instruction{isload} ) {
	    $reg[$instruction{rd}] = getmem($addr,$instruction{byte});
	}
	else {
	    setmem($addr,$reg[$instruction{rd}],$instruction{byte});
	}
    }
    elsif ( $instruction{kind} eq 'SWI' ) {
	printf "SWI\t%8d\t%06X\n", $instruction{swi}, $instruction{swi};
	if ( $instruction{swi} == 0x11 ) { last } # OS_Exit
    }
    else {
	throw("Undefined instruction of type $instruction{kind}");
    }

    $reg[15] += 4;			# Next instruction
}
if ( $mode == 2 ) {
    print STDERR "Disassembly complete.\n" if $v >= 0;
}
else {
    print "Program complete.\n" if $v >= 0;
}

sub parse_instruction {
    my ($binary) = @_;

    my $kind = armbits($binary,27,3); # 00=DataProcess, 101=Branch,
                                      # 01=Ld/St, 011 = local
    # 000 DPI
    # 001 DPI
    # 010 LDR/STR
    # 011 LDR/STR/ARMPL
    # 100 LDM/STM [Unimplemented]
    # 101 B/BL
    # 110 Coprocessor [Unimplemented]
    # 111 Coprocessor [Unimplemented]/SWI

    my %instruction = ();
    $instruction{binary} = $binary; # For the disassembler.

    my $cond = armbits($binary,31,4);
    foreach (keys %conds ) {
	if ( $conds{$_} eq $cond ) { $instruction{cond} = $_; last }
    }

    if ( armbits($binary,27,4) eq '0000' and armbits($binary,7,4) eq '1001' ) {
	$instruction{kind} = 'DPIX';	# MUL, MULS, MLA, MLAS
	# Unsupported
	$instruction{kind} = 'CONSTANT';
	$instruction{immediate} = bin2dec($binary);
    }
    elsif ( $kind eq '000' or $kind eq '001' ) { # Data Processing Instruction
	$instruction{kind} = 'DPI';
	$instruction{opcode} = armbits($binary,24,4);
	$instruction{sbit} = armbits($binary,20,1) eq '1' ? 1 : 0;
	$instruction{rn} = bin2dec(armbits($binary,19,4));
	$instruction{rd} = bin2dec(armbits($binary,15,4));
	if ( armbits($binary,25,1) eq '1' ) {
	    my $immed = bin2dec(armbits($binary,7,8));
	    my $offset = bin2dec(armbits($binary,11,4))*2;
	    $instruction{offset} = $offset;
	    $instruction{offsetreg} = 0;
	    $instruction{shifttype} = 3; # ROR
	    $instruction{source} = $immed;
	    $instruction{srcimmed} = 1;
	}
	else {
	    $instruction{source} = bin2dec(armbits($binary,3,4));
	    $instruction{srcimmed} = 0;

	    # Shift register
	    my $oir = armbits($binary,4,1) eq '1' ? 1 : 0;
	    $instruction{shifttype} = bin2dec(armbits($binary,6,2)) || -1;
	    $instruction{offsetreg} = $oir;
	    $instruction{offset} = bin2dec(armbits($binary, 11, $oir ? 4 : 5));
	}
    }
    elsif ( $kind eq '101' ) {		# Branch
	$instruction{kind} = 'B';
	$instruction{link} = armbits($binary,24,1);
	$instruction{immediate} = bin2dec(armbits($binary,23,24));
	if ( $instruction{immediate}&(1<<23) ) {
	    $instruction{immediate} -= 1<<24;
	}
	$instruction{immediate} <<= 2;
    }
    elsif ( $kind eq '010' or $kind eq '011' ) { # Load, Store and NonStandard
	if ( armbits($binary,24,5) eq '11111'
	     and $kind eq '011' and armbits($binary,7,4) eq '1111'
	     #and armbits($binary,4,1) eq '1'
	   ) {
	    # arm.pl nonstandard
	    $instruction{kind} = 'ARMPL';
	    my $opcode = armbits($binary,19,4);
	    if ( $opcode =~ /^00/ ) {
		$instruction{opcode} = 'OUT';
		if    ( $opcode eq '0001' ) { $instruction{format} = 'HEX'   }
		elsif ( $opcode eq '0010' ) { $instruction{format} = 'BYTES' }
		elsif ( $opcode eq '0011' ) { $instruction{format} = 'IMMED' }
		else { $instruction{format} = 'DEFAULT' }
		if ( $opcode eq '0011' ) {
		    $instruction{immediate} = bin2dec(armbits($binary,15,8));
		}
		else {
		    $instruction{reg} = bin2dec(armbits($binary,15,4));
		    #$instruction{regb} = bin2dec(armbits($binary,11,4));
		    #$instruction{regc} = bin2dec(armbits($binary,3,4));
		}
	    }
	    elsif ( $opcode eq '0100' or $opcode eq '0101' ) {
		$instruction{opcode} = $opcode eq '0100' ? 'END' : 'DIE';
	    }
	    #print $instruction{opcode}.($instruction{format}||'').' '.($instruction{immediate}||(exists($instruction{rega})?('R'.($instruction{rega}||'0').', R'.($instruction{regb}||'').', R'.($instruction{regc}||'')):''))."\n";
	}
	else {
	    $instruction{kind} = 'MEMOR';
	    $instruction{isload} = armbits($binary,20,1)?1:0;
	    $instruction{rd} = bin2dec(armbits($binary,15,4));
	    $instruction{rn} = bin2dec(armbits($binary,19,4));
	    $instruction{byte} = armbits($binary,22,1)?1:0;
	    $instruction{positive} = armbits($binary,23,1)?1:0;

	    if ( !armbits($binary,25,1) ) { # Immediate offset
		$instruction{offset} = bin2dec(armbits($binary,11,12));
		$instruction{offsetimmed} = 1;
	    }
	    else {			# Register offset
		$instruction{offset} = bin2dec(armbits($binary,3,4));
		$instruction{offsetimmed} = 0;
		if ( bin2dec(armbits($binary,11,8)) ) { # Scaled Register
		    throw("Scaled register offset is not supported");
		}
	    }

	    # Various unsupported strangeness
	    my $P = armbits($binary,24,1)?1:0;
	    my $W = armbits($binary,21,1)?1:0;
	    if ( $W && !$P ) {
		throw("LDR/STR T mode is not supported")
	    }
	    elsif ( $W && $P ) {
		throw("Pre-indexed addressing is not supported")
	    }
	    elsif ( !$P ) { throw("Post-indexed addressing is not supported") }
	    elsif ( $P && !$W ) { }
	}
    }
    elsif ( armbits($binary,27,4) eq '1111' ) {
	$instruction{kind} = 'SWI';
	my $swi = bin2dec(armbits($binary,23,24));
	$instruction{swi} = $swi;
	#printf "SWI &%06X\n",$swi;
    }
    elsif ( $mode == 2 ) {
	$instruction{kind} = 'CONSTANT';
	$instruction{immediate} = bin2dec($binary);
    }
    else {
	throw("Undefined instruction at ".($reg[15]-8)."(+8): ".
	      bin2hex($binary));
    }
    return \%instruction;
}

sub disassemble_instruction {
    my %instruction = %{shift @_};
    my $cond = $instruction{cond};
    $cond = '' if $cond eq 'AL';

    if ( $instruction{kind} eq 'SWI' ) {
	 return sprintf('SWI%s &%06X',$cond,$instruction{swi});
    }
    elsif ( $instruction{kind} eq 'DPI' ) {
	my $ins = '';
	foreach ( keys %instructions ) {
	    if ( $instructions{$_} eq $instruction{opcode} ) {
		$ins = $_;
		last;
	    }
	}
	$ins .= $cond;

	# TST, TEQ, CMP, CMN
	$ins.= 'S' if $instruction{sbit} and $instruction{opcode} ne '1000' and
	  $instruction{opcode} ne '1001' and $instruction{opcode} ne '1010'
	    and $instruction{opcode} ne '1011';
	$ins .= ' ';

	$ins .= 'R'.$instruction{rn}.', ' if $instruction{opcode} ne '1101' and
	  $instruction{opcode} ne '1111'; # MOV and MVN

	$ins .= 'R'.$instruction{rd}.', ' if $instruction{opcode} ne '1000' and
	  $instruction{opcode} ne '1001' and $instruction{opcode} ne '1010'
	    and $instruction{opcode} ne '1011';

	# Operand 2
	if ( $instruction{srcimmed} ) {
	    $ins .= "#$instruction{source}";
	    if ( $instruction{offset} ) {
		$ins .= ', '.offset_to_str($instruction{shifttype}).' #'
		  .$instruction{offset};
	    }
	}
	else {
	    $ins .= 'R'.$instruction{source};
	    if ( $instruction{offset} || $instruction{offsetreg} ) {
		$ins .= ', '.offset_to_str($instruction{shifttype}).' ';
		$ins .= ($instruction{offsetreg}?'R':'#').$instruction{offset};
	    }
	}
	return $ins;
    }
    elsif ( $instruction{kind} eq 'B' ) { # TODO
	my $ins = 'B';
	$ins .= 'L' if $instruction{link};
	$ins .= "$cond ";
	$ins .= $reg[15]+$instruction{immediate};
    }
    elsif ( $instruction{kind} eq 'ARMPL' && $instruction{opcode} eq 'OUT' ) {
	my $ins = 'OUT';
	$ins .= "$cond ";
	if    ( $instruction{format} eq 'HEX'   ) { $ins .= 'S' }
	elsif ( $instruction{format} eq 'BYTES' ) { $ins .= 'B' }

	if ( $instruction{format} eq 'IMMED' ) {
	    $ins .= '#'.$instruction{immediate}
	}
	else {
	    $ins .= 'R'.$instruction{reg};
	}
	return $ins;
    }
    elsif ( $instruction{kind} eq 'ARMPL' and ($instruction{opcode} eq 'END' or $instruction{opcode} eq 'DIE') ) {
	return $instruction{opcode}.$cond;
    }
    elsif ( $instruction{kind} eq 'MEMOR' ) {
	my $ins = $instruction{isload}?'LDR':'STR';
	$ins .= $cond;
	$ins .= 'B' if $instruction{byte};
	$ins .= " R$instruction{rd}, [R$instruction{rn}";
	{ # TODO
	    $ins .= ', ';
	    $ins .= $instruction{offsetimmed} ? "#$instruction{offset}"
	      : (($instruction{positive}?'':'-')."R$instruction{offset}");
	    $ins .= ']';
	}
    }
    elsif ( $instruction{kind} eq 'CONSTANT' ) {
	return 'DCW #'.$instruction{immediate};
    }
    else {
	return "UNKNOWN";
    }
}

sub offset_to_str {
    my ($kind) = @_;
    if    ( $kind == -1) { return 'LSL' }
    elsif ( $kind == 0 ) { throw("Bad Offset Type") }
    elsif ( $kind == 1 ) { return 'LSR' }
    elsif ( $kind == 2 ) { return 'ASR' }
    elsif ( $kind == 3 ) { return 'ROR' }
    else { throw("Bad Offset Type") }
}

sub throw {
    my ($msg) = @_;
    my @caller = caller;
    die $msg.($msg !~ /\n$/ ? " at $caller[1] line $caller[2].\n":'');
}

sub isreg {
    my ($pos) = @_;
    $pos = uc $pos;
#    vprint "TODO: R15 only contains PC. See http://www.heyrick.co.uk/assembler/psr.html\n" if $pos eq 'PC' or $pos eq 'R15';
    return 15 if $pos eq 'PC';
    return 14 if $pos eq 'LR';
    if ( $pos =~ /^R(\d+)$/ ) {
	return undef unless $1 >= 0 && $1<=15;
	return $1+0;#wantarray ? [1,$reg[$1]] : 1;
    }
    return undef;
}

sub parse_operand2 {			# Returns an array with two items.
    my ($val) = @_;			# 1 is I bit, 2 12 bits of the value

    $val ||='';

    my $I = '0';
    my $out = '';

    my $offset = 0;
    my $offsetreg = 0;
    my $offsetshift = 0;

    my $brackets = 0;			# 1=[] around reg, 2=[] around whole
    my $excl = 0;
    # [.+]!? code missing
    if ( $val =~ s/^\[(.+)\](!)?$/$1/ ) {	# Address
	$brackets = 2;
	if ( $2 ) { $excl = 1 }
    }
    elsif ( $val =~ s/^(\[(\w+)\])/isreg($2)?$1:$2/e ) {
	$brackets = 1;
    }

    my $U = 1;
    if ( $val =~ s/\s*,\s*(.+)$// ) { # If there is a FOP
	my $fop = $1;

	if ( $val =~ s/\+// ) { }
	elsif ( $val =~ s/-// ) { $U = 0 }

	# Bug - For Addr Mode 2, shifting expects another register

	#vprint "FOP: $1\n";
	if ( $fop =~ /^([#&][+-]?[\da-fx]+|R\d+|PC)$/i ) { # Numbers
	    # If it is a number or register, you add that to the
	    # result

	    # +/- bugs here
	    my $o = $1;
	    my $r;
	    if ( $r = isreg($o) or defined($r) ) {
		$offset = $r;
		$offsetreg = 1;
	    }
	    else { $offset = isimmed($o)||0; }
	}
	elsif ( $fop =~ /^($fopmatch)\s+(R\d+|[#&][0-9a-fx]+)$/i ) {
	    my $fopkind = uc $1;
	    my $fopby = 0;
	    my $o = $2;
	    my $r;
	    if ( $r = isreg($o) or defined($r) ) {
		$fopby = $r;
		$offsetreg = 1;
	    }
	    else { $fopby = isimmed($o)||0; }

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

    if ( $brackets ) {			# Addressing mode 2
	my ($I,$P,$W) = (1,0,0);
	if ( $offsetshift ) {
	    if ( $offset ) {
		$out = dec2bin($offset+0,5);
		if   ( $offsetshift == -1 ) { $out .= $offsetreg? '0001':'000'}
		elsif ( $offsetshift == 1 ) { $out .= $offsetreg? '0011':'010'}
		elsif ( $offsetshift == 2 ) { $out .= $offsetreg? '0101':'100'}
		elsif ( $offsetshift == 3 ) { $out .= $offsetreg? '0111':'110'}
	    }
	}
	elsif ( $offsetreg ) {
	    $out = '00000000';
	    $out .= dec2bin($offset,4);
	}
	else {
	    $out = dec2bin($offset,12);
	    $I=0;
	}

	if ( $brackets == 1 ) { $P = 0 }
	else { $P = 1;
	       $W = $excl ? 1 : 0;
	   }
	return ($I,$P,$U,$W,$val,$out);
    }
    else {				# Addressing mode 1
	my $f;
	if ( $f = isreg($val) or defined($f)) {
	    if ( $offset or $offsetreg ) {
		$out = ' '.dec2bin($offset+0,($offsetreg?4:5));
		if   ( $offsetshift == -1 ) { $out .= $offsetreg? '0001':'000'}
		elsif ( $offsetshift == 1 ) { $out .= $offsetreg? '0011':'010'}
		elsif ( $offsetshift == 2 ) { $out .= $offsetreg? '0101':'100'}
		elsif ( $offsetshift == 3 ) { $out .= $offsetreg? '0111':'110'}
	    }
	    elsif ( 0 ) {
		$out = ' 00000110';
	    }
	    else {
		$out = ' 00000000';	# shifter_operand	11-4
	    }
	    $out .= dec2bin($f,4);	# shifter_operand	3-0
	}
	elsif ( $f = isimmed($val) or defined($f) ) {
	    $I='1';
	    $out = ' 0000'.dec2bin($f,8);	# shifter_operand	11-0
	}
	else { $out = ' ????????????'; }
	return ($I,$out);
    }
}

sub isimmed {
    my ($val) = @_;
    if ( $val =~ /^#([+-]?\d+)$/ ) { # Numbers
	return $1+0;
    }
    elsif ( $val =~ /^(?:&|#0x)([\dA-F]+)$/i ) { # Hex Numbers (?)
	return hex($1);
    }
    else {
	return undef;
    }
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

sub getmem {
    my ($index,$byteonly) = @_;
    $memory .= chr(0)x($index-length($memory)+8)
      if length($memory) < $index+4;
    if ( $byteonly ) { return ord(substr($memory,$index,1)) }
    else { return unpack('V',substr($memory,$index,4)) } # See $memory comment
}

sub setmem {
    my ($index,$content,$byteonly) = @_;
    $memory .= chr(0)x($index-length($memory)+8)
      if length($memory) < $index+4;
    if ( $byteonly ) { return substr($memory,$index,1,chr($content)) }
    else { return substr($memory,$index,4,pack('V',$content)) }
}

sub MungeString {			# Munge string for use in DCB
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

# Various and sundry type conversions
sub dec2bin { # From http://www.infocopter.com/perl/character-encoding.htm
    my ($dec,$bits) = @_;
    my $bin = substr(sprintf("%032b", $dec),-$bits);
    my $padding = 0;
    #$padding = $bits - length($bin) % $bits if length($bin) % $bits;
    #return substr('0'x$bits, 0, $padding) . $bin;
    return $bin;
}
sub bin2chars {
    my ($bin) = @_;
    $bin =~ s/\s//g;
    if ( $bin =~ s/^(0b)?([01]+)$/0b$2/ ) {
	return pack('V',eval $bin);
    }
    else {
	#print "FAILED TO PACK\n";
	return pack('V',0);
    }
}

sub bin2hex {
    my ($bin) = @_;
    $bin =~ s/\s//g;
    if ( $bin =~ s/^(0b)?([01]+)$/0b$2/ ) {
	return sprintf("%08X",eval $bin);
    }
    else {
	#print "FAILED TO PACK '$bin'\n";
	return (' 'x8);
    }
}

sub bin2dec {
    my ($bin) = @_;
    $bin =~ s/\s//g;
    if ( $bin =~ s/^(0b)?([01]+)$/0b$2/ ) {
	return eval $bin;
    }
    return 0;
}

sub armbits { # Like substr, except taking $_[1] as 31-0. For convenient
    return substr($_[0],31-$_[1],$_[2]); # compatibility with DDI-0100E

}

__END__
# Licensed under a Creative Commons License.

<!--
<rdf:RDF xmlns="http://web.resource.org/cc/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<Work rdf:about="">
   <license rdf:resource="http://creativecommons.org/licenses/GPL/2.0/" />
   <dc:type rdf:resource="http://purl.org/dc/dcmitype/Software" />
</Work>

<License rdf:about="http://creativecommons.org/licenses/GPL/2.0/">
   <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
   <permits rdf:resource="http://web.resource.org/cc/Distribution" />
   <requires rdf:resource="http://web.resource.org/cc/Notice" />
   <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
   <requires rdf:resource="http://web.resource.org/cc/ShareAlike" />
   <requires rdf:resource="http://web.resource.org/cc/SourceCode" />
</License>

</rdf:RDF>
-->
