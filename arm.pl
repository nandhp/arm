#!/usr/bin/perl
#
# Perl ARM Simulator
#
# Copyright (c) 2005-2006 nandhp. Licensed under the GNU GPL.
# http://www.gnu.org/copyleft/gpl.html
#

use strict;
use warnings;
use integer;
use Getopt::Long qw(:config gnu_getopt);
use Pod::Usage;
use Term::ReadLine;
use constant {B => 0, DPI => 1, MUL => 2, MRS => 3, MSR => 4, CLZ => 5,
	      ARMPL => 6, MEMOR => 7, LDM => 8, SWI => 9, BKPT => 10,
	      ARMEND => 11, ARMDIE => 12, CONSTANT => 13, UNKNOWN => 14,
	      DEFAULT => 15, IMMED => 16, OUT => 17, HEX => 18, BYTES => 19 };
use constant {EQ=>0, NE=>1, CS=>2,  CC=>3,  MI=>4,  PL=>5,  VS=>6,  VC=>7,
	      HI=>8, LS=>9, GE=>10, LT=>11, GT=>12, LE=>13, AL=>14, NV=>15};

my $VERSION='20060823'; # yyyymmdd

$| = 1;					# Autoflush on

# Load Compress:Zlib module, if available
my $use_zlib = eval 'use Compress::Zlib;1' || 0;
my $allow_readkey = eval 'use Term::ReadKey;1' || 0;

# Load ARM ARGV
my @arm_argv = ();
for ( my $i=0; $i <= $#ARGV; $i++ ) {
    if ( $ARGV[$i] eq '-' or $ARGV[$i] eq '--' ) {
	@arm_argv = @ARGV[($i+1)..$#ARGV];
	$#ARGV = $i-1;
    }
}
@arm_argv = ($ARGV[0]||'arm.pl') if @arm_argv == 0;


# Options
my $v = 0;
my $help = 0;
my $man = 0;
my $q = 0;
my $d = 0;
my $no_zlib = 0;
my $dump_debuginfo = 0;
my $elf = 0;
my $startaddr = undef;
my $cacheless = 0;

my $o = '';
my ($mode,$mode_a,$mode_d,$mode_x) = (0,0,0,0);

GetOptions('no-zlib' => \$no_zlib, 'dump-debuginfo' => \$dump_debuginfo, 'debug|d' => \$d, 'verbose|v' => \$v, 'quiet|q' => \$q, 'output|o=s' => \$o, 'help|h|?' => \$help, 'assemble|a' => \$mode_a, 'disassemble|D' => \$mode_d, 'execute|x' => \$mode_x, 'readelf' => \$elf, 'startaddr=s' => \$startaddr, 'no-cache' => \$cacheless, 'man' => \$man, 'version|V' => \&show_version) or show_help();
show_help(1) if $help;
show_help(2) if $man;

$use_zlib = 0 if $no_zlib;
$use_zlib = 0 if $mode_a && ( $mode_x || $mode_d );

# Autodetect mode based on provided filename(s).
if ( !$mode_a && !$mode_d && !$mode_x ) {
    if ( scalar(@ARGV) != 1 ) {		# Assume anything but one parameter
	$mode_a = 1;			# should be assembled
    }
    elsif ( $ARGV[0] eq '-' ) {
	$mode_a = 1;
    }
    else {				# File not found, File contents
	open TEST, $ARGV[0] or throw("Can't open $ARGV[0]: $!");
	my $line;
	read(TEST,$line,4);		# If the first line has
	if ( $line =~ /^#!/ ) { $mode_a = 1 } # a shebang,
	elsif ( $line =~ /^;/ ) { $mode_a = 1 } # a comment,
	elsif ( $line =~ /^[\s._a-zA-Z0-9;@]{3}/ ) { $mode_a = 1 }
	# or something similar to an indented assembler instruction, then
	# Assemble it.
	elsif ( $line =~ /^\177ELF/ && !defined($startaddr) ) {
	    # If it is in ELF format...
	    $elf = 1;
	    $mode_x = 1;
	}
	else { $mode_x = 1 } # If not, execute it.
	close TEST;
    }
}

if ( $dump_debuginfo ) {$d=1;$mode_a=0;$mode_x=0;$mode_d=1;$q=1}

# Default output filename
if ( $mode_a && !$mode_x && !$mode_d && !$o ) {
    $o = 'a.out';
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

if ( $d && $mode == 1 ) {
    print "Assembling with debug information...\n";
}
elsif ( $d && $mode == 3 || $mode == 2 ) {
}
$startaddr ||= 0;
$startaddr = oct($startaddr) if $startaddr =~ m/^0/i;
$v = -1 if $q;

=head1 NAME

arm.pl - ARM Assembler, Disassembler and Interpreter written in Perl

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

In execution mode, execute with the ARM Debugger. In assembly mode,
assemble with debugging information. In disassembly and execution
modes, having a binary compiled with debugging information will
provide much more helpful output.

=item B<--no-zlib>

Disallow the use of Zlib compression.

=item B<--dump-debuginfo>

Inflate (if deflated) and output the debugging information.

=item B<--quiet>, B<-q>

Be quiet. This will cause the default behavior, to output each
instruction as it is executed, to be turned off. This switch is
ignored when B<--debug> is specified.

=item B<--verbose>, B<-v>

Be verbose -- more verbose then the default -- during the parsing,
assembly and execution phases. If the default verbosity is too verbose
and you are looking for a way to stop all nonessential messages, try
B<--quiet>.

=item B<--readelf>

Use readelf(1) to parse input.

=item B<--no-cache>

Disable the instruction cache.

=item B<--startaddr> I<address>

Start executing or disassembling at the given address. Ignored if
B<--readelf> is present.

=item B<--version>, B<-V>

Display the arm.pl version number and check for updates.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Display the full documentation, for which you may want to use a pager.

=item B<-->

Specifies that all subsequent command-line arguments should be passed
to the ARM program being executed, I<including> argv[0].

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

=item B<b>[ I<location>]

Set a breakpoint.

=item B<d>[ I<location>]

Clear a previously-set breakpoint. See B<b>.

=item B<l>[ I<location>]

List the next ten instructions, starting at I<location> or defaulting
to various sensible defaults which involve you being able to enter
B<l> repeatedly to view more of the file, like the perl debugger.

=item B<v>[ I<location>]

Same as B<l>, except the first window it displays will also show
several instructions prior to the specified (or default) line.

=item B<w>[ I<location>]

Provides the filename and line number of the given location (if available).

=item B<r>[x|b][I<number>[=I<value>]]

Display the contents of the given register. If B<x> is provided,
displays it in hex, if B<b> is provided, displays it as byte(s).

If no register I<number> is provided, all registers are displayed. If
I<value> is specified, the specified register will be set to I<value>.

=item B<cpsr|spsr>

Displays the contents of the CPSR or SPSR.

=item B<n>

Execute the next instruction and display another prompt.

=item [q]B<c>

Execute the next instruction and continue until a breakpoint is
reached or the program terminates. If Q is specified, the debugger
will not display instructions during execution, returning to normal
verbosity at the next breakpoint.

=item B<R>

Reset. Clear all registers and return to starting instruction. Does
not clear, reset or reload memory.

=item B<q>

Quit.

=back

Locations can be provided to ARM Debugger commands in several ways: By
memory address, by label, or by line numbers.

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

=head1 EXAMPLES

=over 8

=item B<arm.pl -d a.out>

Automatically detect the format and of a.out and run it with debugging
support (ARM Debugger in execute, allowing use of Debugging
Information in Assembler and Disassembler).

=item B<arm.pl -qx a.out>

Execute a.out quietly.

=item B<arm.pl -q busybox.bin -- echo -e Hello, world>

(Presumably) execute busybox.bin with argv[0] set to "echo", and some
command-line arguments in argv[1..4].

=back

=head1 BUGS

None

=head1 AUTHOR

nandhp <nandhp@gmail.com>

=cut

sub show_version {
    print "arm.pl version $VERSION\n\nChecking for updates...";
    my $asu_host = $ENV{ASU_HOST}||'nand.homelinux.com:8888';
    my @vup = split("\n",eval('use LWP::Simple;return get("http://'.$asu_host.'/~nand/blosxom/update/au_check.cgi")')||'');
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
	if ( -f 'update.pl' ) {
	    print "Run update.pl to upgrade to this version.\n";
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

sub nprint     { print @_ if $v >= 0 } sub nprintf    { printf @_ if $v >= 0 }
sub vprint     { print @_ if $v >= 1 } sub vprintf    { printf @_ if $v >= 1 }
sub vvprint    { print @_ if $v >= 2 } sub vvprintf   { printf @_ if $v >= 2 }

# Generate lists of things
my %conds= ();
my @rdpi = qw/AND EOR SUB RSB ADD ADC SBC RSC TST TEQ CMP CMN ORR MOV BIC MVN/;
my @conds= qw/EQ NE CS CC MI PL VS VC HI LS GE LT GT LE AL NV/;
my @kinds= qw/B DPI MUL MRS MSR CLZ ARMPL MEMOR LDM SWI/;
my @iswis= qw/BKPT ARMEND ARMDIE/; # SWIs internally
my    $ConditionEval = '(';
my    $AssemblerEval = '(';
my      $DecoderEval = '(';
my     $ExecutorEval = '(';
my $DisassemblerEval = ' ';
my  $DPIExecutorEval = '(';
for (my $i=0;$i<=$#conds;$i++ ) { # Generate functions for conditionals
    $conds{$conds[$i]} = sprintf('%04b',$i);
    $ConditionEval .= '\&Condition_'.$conds[$i].',';
}
my $swionly = 0;
foreach ( @kinds, 0, @iswis ) { # Generate functions for instruction kinds
    ($swionly = 1, next) unless $_;
    $AssemblerEval     .= '\&Assemble_'.$_.',';
    $DecoderEval       .= '\&Decode_'.$_.',';
    $ExecutorEval      .= '\&Execute_'.($swionly?'SWI':$_).',';
    $DisassemblerEval  .= '\&Disassemble_'.$_.',';
}
foreach ( @rdpi ) { # Generate functions for DPIs
    $DPIExecutorEval   .= '\&DPI_'.$_.',';
}
my    @Conditions = eval(   $ConditionEval.')');
my    @Assemblers = eval(   $AssemblerEval.')');
my      @Decoders = eval(     $DecoderEval.')');
my     @Executors = eval(    $ExecutorEval.')');
my @Disassemblers = (eval($DisassemblerEval   ),
		     sub { # CONSTANT
			 my ($mempos,$cond,$instruction) = @_; # FIXME optimze
			 return sprintf('DCW &%X',$instruction->{decimal});
		     },
		     sub { return 'UNKNOWN' }, # UNKNOWN
		    );
my  @DPIExecutors = eval( $DPIExecutorEval.')');
my @DeclassifyByKind = ( \&Declassify_DPI0, # 000 - DPI, CIES, Multiply
			 \&Declassify_DPI1, # 001 - DPI, MSR
			 \&Declassify_LDRI, # 010 - LDR/STR Immediate Offset
			 \&Declassify_LDRR, # 011 - LDR/STR Register Offset
			 \&Declassify_LDM,  # 100 - LDM/STM
			 \&Declassify_B,    # 101 - B/BL
			 \&Declassify_CPLS, # 110 - Coprocessor LDR/STR/DRT
			 \&Declassify_CPSI, # 111 - Coprocessor DP/RT, SWI
		       );
my @DeclassifyCPSI = ( sub { 0 }, \&Decode_SWI );
my @DeclassifyARMPL = ( \&Decode_ARMPL, # 0000 OUT  Register
			\&Decode_ARMPL, # 0001 OUTS Register/Hex
			\&Decode_ARMPL, # 0010 OUTB Register/Bytes
			\&Decode_ARMPL, # 0011
			\&Decode_ARMEND,# 0100
			\&Decode_ARMDIE,# 0101
			eval('sub { 0 },'x10));
my %SWI = ( 0x02 => \&SWI_OS_Write0,
	    0x11 => \&SWI_OS_Exit,
	    0x12 => \&SWI_ARMSIM_BKPT,
	    0x13 => \&SWI_ARMSIM_DIE,
	    0x14 => \&SWI_ARMSIM_GETC,
	    0xF00000 => sub { }, # IMB All, see DDI0100E pg A2-29
	    0xF00001 => sub { }, # IMB Range, see DDI0100E pg A2-29
	    0x900001 => \&SWI_sys_exit,
	    0x900003 => \&SWI_sys_read,
	    0x900004 => \&SWI_sys_write,
	    0x900005 => \&SWI_sys_open,
	    0x900006 => \&SWI_sys_close,
	    0x90000D => \&SWI_sys_time,
	    0x900014 => \&SWI_sys_getpid,
	    0x900018 => \&SWI_sys_getuid, # sys_getuid16
	    0x90002F => \&SWI_sys_getgid, # sys_getgid16
	    0x900031 => \&SWI_sys_getuid, # sys_geteuid16
	    0x900032 => \&SWI_sys_getgid, # sys_getegid16
	    0x900036 => \&SWI_sys_ioctl,
	    0x90005A => \&SWI_sys_mmap,
	    0x9000C7 => \&SWI_sys_getuid, # sys_getuid
	    0x9000C8 => \&SWI_sys_getgid, # sys_getgid
	    0x9000C9 => \&SWI_sys_getuid, # sys_geteuid
	    0x9000CA => \&SWI_sys_getgid, # sys_getegid
	  );
opendir DIR, '.';
foreach ( readdir DIR ) {
    next if m/^\./;
    next unless -f $_;
    next unless m/\.swi$/;
    do $_;
}
closedir DIR;

my %instructions = (
		    # Unimplemented instructions

		    # Implemented instructions
		    'AND' => '0000',
		    'EOR' => '0001',
		    'SUB' => '0010',
		    'ADD' => '0100',
		    'ADC' => '0101',
		    'CMP' => '1010',
		    'ORR' => '1100',
		    'MOV' => '1101',
		    'B'   => '-1',
		    'BL'  => '-1',
		    'BX'  => '-6',
		    'BLX' => '-6',
		    'BKPT'=> '-6',
		    'SWI' => '-4',
		    # Beta instructions
		    'RSB' => '0011',
		    'SBC' => '0110',
		    'RSC' => '0111',
		    'TST' => '1000',
		    'TEQ' => '1001',
		    'MVN' => '1111',
		    'LDR' => '-2',
		    'STR' => '-2',
		    'LDM' => '-5',
		    'STM' => '-5',
		    # Alpha instructions
		    'CMN' => '1011',
		    'BIC' => '1110',
		    'CLZ' => '-6',
		    'MSR' => '-7',
		    'MRS' => '-7',
		    'MUL' => '-8',
		    'MLA' => '-8',

		    # Nonstandard instructions
		    'ADR' => '-3',
		    'NOP' => '-3',
		    'DIE' => '-3',
		    'END' => '-3',
		    'OUT' => '-3',
		   );

my %extra = (
	     S  => 1,
	     H  => 1,
	     T  => 1,
	     B  => 1,
	     BT => 1,

	     # LDM and STM
	     DA => '00',
	     IA => '01',
	     DB => '10',
	     IB => '11',

	     EDS => '00',
	     EAS => '01',
	     FDS => '10',
	     FAS => '11',

	     FAL => '00',
	     FDL => '01',
	     EAL => '10',
	     EDL => '11',
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
my %breaks = ();
my %labels = ();
my %regalias = (R0 => 0, R1 => 1, R2 => 2, R3 => 3, R4 => 4, R5 => 5, R6 => 6,
		R7 => 7, R8 => 8, R9 => 9, R10=>10, R11=>11, R12=>12, R13=>13,
		R14=>14, R15=>15, PC =>15, LR =>14, SP =>13, IP =>12, FP =>11,
		SL => 10);

my $memory = ''; # Big endian

my $condmatch	= join('|',keys %conds);
my $insmatch	= join('|',keys %instructions);
my $xmatch	= join('|',keys %extra);
   $xmatch	=~s/([DA])[SL]\|/$1|/g;
my $fopmatch	= join('|',keys %operand_flags);
my $immedmatch	= '(?:[+-]?[#&][+-]?(?:0x)?(?:[\da-fA-F]+))';
my $labelmatch	= '(?:[._a-zA-Z0-9]+)';
my $commentchar	= '@;';

my $insnum = 0;
my $mempos = 0;
my $includefn = scalar(@ARGV)>1?1:0;
my $lastlabel='';

goto disassemble if $mode > 1;		# I know that GOTO is bad, but I did
                                        # not want to have to indent all of
                                        # the next 300 lines.

# Process the program
nprint "Parsing source...\n";

while (my $line = <>) {
    $line =~ s/[\r\n]//g;
    #vprint '='x70,"\n$line\n";
    next if $line =~ /^\s*[$commentchar]/;
    next if $line =~ /^#!/;
    next if $line =~ /^\s*$/;
    $line =~ s/\s*$//;

    # Register alias
    if ( $line =~ /^([a-z0-9]+)\s*\.req\s*R?(\d+)([$commentchar]|$)/i ) {
	$regalias{$1}=$2+0;
	next;
    }
    if ( my ($sudo) = $line =~ m/^\s+\.(.+)([$commentchar]|$)/ ) {
	# Pseudo operands
	if ( $sudo =~ /^\.unreq\s*(.+)$/i ) {
	    if ( !exists $regalias{$1} ) {
		die "Undefined register alias in .unreg";
	    }
	    delete $regalias{$1};next;
	}
	elsif ( $sudo =~ /^ascii\s+(.+)/i ) {
	    $line = " DCB $1";
	}
	elsif ( $sudo =~ /^word\s+(.+)/i ) {
	    $line = " DCW #".$labels{lc $1};
	}
	elsif ( $sudo =~ /^file\s/i ) { next }
	elsif ( $sudo =~ /^align\s/i ) { next }
	elsif ( $sudo =~ /^global\s/i ) { next }
	elsif ( $sudo =~ /^type\s/i ) { next }
	elsif ( $sudo =~ /^size\s/i ) { next }
	elsif ( $sudo =~ /^type\s/i ) { next }
	elsif ( $sudo =~ /^section\s/i ) { next }
	elsif ( $sudo =~ /^ident\s/i ) { next }
	elsif ( $sudo =~ /^text\s*/i ) { next }
	elsif ( $sudo =~ /^loc\s*/i ) { next }
	elsif ( $sudo =~ /^[24]?byte\s*/i ) { next }
	elsif ( $sudo =~ /^[us]leb128\s*/i ) { next }
	else { throw("Unrecognized pseudo-op $sudo at $ARGV:$.") }
    }

    # Check for a label
    if ( $line =~ s/^($labelmatch)(:|\s|$)// ) {
	my ($label,$ws) = (lc $1,$2);
	if ( $labels{$label} ) {
	    print "Warning: Duplicate label $1\n";
	}
	$lastlabel=$label;
	vprintf "%s[%X]:\n",$label,$mempos;
	$labels{$label}=$mempos;
    }

    $line =~ s/^\s*//; # Remove remaining indentation
    next unless $line;

    if ( $line =~ /^DC([BDW])\s+(.+)$/i ) {
	my $bdw = uc $1;
	my $vals = $2;
	#vprint "Processing DC$bdw...\n";
	if ( $bdw eq 'D' ) {		# Define Constant Data doesn't act
	    $bdw = 'W';			# constant here... See ARMBook p29
	}

	# A quote followed by a bunch of stuff and then another quote
	# that is not preceeded by a backslash.
	$vals =~ s/\"(.+?)(?<!\\)\"/MungeString($1)/ge;
	$vals =~ s/[$commentchar].+$//; # Remove stray comments

	if ( $bdw eq 'B' ) {
	    vprintf "%X:\tDCB\n",$mempos;
	    # $labels{$lastlabel}=$mempos if $lastlabel;
	    foreach ( split ',', $vals ) {
		s/^\s*|\s*$//g;
		my $value = isimmed($_)||0;
		setmem($mempos,$value,1);
		vprintf "  %X:\t&%X\n", $mempos, $value;

		$program[@program] = [$mempos,"DCB"] unless $mempos % 4;
		$mempos++;
	    }
	}
	elsif ( $bdw eq 'W' ) {
	    while ( $mempos%4 ) {	# ALIGN
		setmem($mempos,0,1);
		$mempos++;
	    }
	    #$labels{$lastlabel}=$mempos if $lastlabel;
	    vprintf "%X:\tDCW\n",$mempos;
	    foreach ( split ',', $vals ) {
		s/^\s*|\s*$//g;
		my $value = isimmed($_)||0;
		setmem($mempos,$value,0);
		vprintf "  %X:\t&%X\n", $mempos, $value;

		$program[@program] = [$mempos,"DCW"];
		$mempos+=4;
	    }
	}
	else { throw("Bad DC{X} DC$1 at $ARGV:$.\n") }
	vprint "\n";
	$lastlabel='';
	next;
    }

    while ( $mempos%4 ) {		# ALIGN
	setmem($mempos,0,1);
	$mempos++;
    }
    # $labels{$lastlabel} = $mempos if $lastlabel;

    next if $line =~ /^ALIGN\s*/i;	# ALIGN is automatic
    $line =~ s/[$commentchar].+$//;	# Remove stray comments
    $line =~ s/\s*$//;			# Remove ending whitespace
    next unless $line;
    $lastlabel='';
    $lines[$mempos] = "$ARGV:$.";

    # Parse instruction
    my ($ins) = $line =~ m/^($insmatch)(?=(?:$condmatch|$xmatch)*(?:\s|$))/io
      or throw("Unrecognized instruction at ".strloc($mempos));
    $line = substr($line,length($ins));		# Remove instruction
    my ($extra, $params) = $line =~ m/^($condmatch|$xmatch)*(?:\s+(.+))?$/io;
    defined($extra) or defined($params) or !length($line) or throw("Unrecognized flag or conditional at ".strloc($mempos));
    my ($cond) = $line =~ m/($condmatch)?/io;	# Remove conditional
    $extra =~ s/$cond// if $cond; $cond ||= 'AL'; $params ||= '';

    ($ins,$cond,$extra) = (uc $ins,uc $cond,uc $extra); # Uppercase some
    my @params = split /(,\s*|\s+)/, $params;

    vprintf "%X:\t%s\t%s\t%s\n",$mempos,$ins,$extra,$cond;
    for ( my $i=0; $i<=$#params; $i++ ) {
	splice(@params,$i,1) if $i<$#params and $params[$i] =~ m/^,\s*$/;
	my $arg = $params[$i];
	my $last = 0;
	$last = 1 if $arg =~ m/^[\[\{]/;
	$last = 1 if $i < $#params and substr($params[$i+1],0,1) eq ',' and $params[$i+2] =~ m/^($fopmatch)$/i;
	if ( $last ) {
	    $params[$i] = join('', @params[$i..$#params]);
	    $#params = $i;
	}
    }
    vprint "\t",join("\n\t",@params),"\n";

    my @instruction = ($mempos,$ins,$cond,$extra, @params);
    push @program, \@instruction;

    $mempos+=4;
    vprint "\n";

    # print "$ins\t$extra\t$cond\n",join("\n",@params,''),'='x70,"\n";
    # Here there be dragons and flexible operands
    # my $regmatch = join('|',keys %regalias);
    # while ( $params =~ /\s*([\.\-\+A-Z0-9#&x!]+\s*(,\s*($fopmatch).*)?|\[($regmatch)(,\s*($fopmatch)?\s*(?:#[+-]?\d+|$regmatch))?\]!?|=?[\.\w]+|[CS]PSR(?:_[cxsf]+)?|\{([^\}]+)\}\^?)\s*(,\s*|$)/gi ) {
    #     push @params, $1;
    #     vprint "Param: $1\n";
    # }
    # push @mempos, $mempos;
    # setmem($mempos,$mempos%4,0);	# There is no need to do this
}
continue { close ARGV if eof }		# To reset $.
  ;

# Now produce object code.
nprint "Assembling...\n";

my $OUTPUT = undef;
if ( $o ) {
    open $OUTPUT, '>',$o or die "Can't open output file: $!";
    binmode $OUTPUT;
}

my @memdbg = ();

foreach my $item ( @program ) {
    last unless defined($item);
    my @ins = @{$item};
    $mempos = shift @ins;
    my $out = '';

    my $mps = sprintf '%X', $mempos;
    $mps .= ' 'x(4-length($mps));

    if ( $ins[0] eq 'DCW' or $ins[0] eq 'DCB' ) {
	push @memdbg, $mempos if $d;

	my $tmp = getmem($mempos,0)||0;
	printf "%s %032b   %08X  DATA  %s\n",$mps,$tmp,$tmp,
	  $item eq 'DCW' ? '4 BYTES' : '4x 1 BYTE' if $v >= 1;
	next;
    }

    # Instruction conversions
    #
    # CMP and CMN always have the S bit set
    # NOP becomes MOVNV R0, R0

    my $opcode = $instructions{$ins[0]} or throw("No opcode for $ins[0] at ".strloc($mempos));

    $ins[2] = 'S' if $opcode eq '1010' or $opcode eq '1011'  # CMP and CMN
      or $opcode eq '1000' or $opcode eq '1001'; # TST and TEQ

    if ( $ins[0] eq 'NOP' ) {     # NOP hack - Turn NOP into a MOVNV R0,R0
	$ins[1] = 'AL'; $ins[0] = 'MOV'; $ins[2] = ''; $ins[3] = 'R0';
	$ins[4] = 'R0';
	$opcode = $instructions{$ins[0]};
    }

    if (
	($ins[0] eq 'LDR' and $ins[4] =~ /^=([.\w]+)$/) or
	($ins[0] eq 'ADR' and $ins[4] =~ /^([.\w]+)$/)
       ) {
	my $offset;
	if ( exists($labels{lc $1}) ) { $offset = $labels{lc $1}-$mempos-8 }
	else { throw("Invalid ADR at ".strloc($mempos)) }

	$ins[0] = $offset < 0 ? 'SUB' : 'ADD';
	$opcode = $instructions{$ins[0]};
	$ins[2] = '';
	$ins[4] = 'R15';
	$ins[5] = '#'.abs($offset);
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
	      : throw("Rd must be register at ".strloc($mempos));

	    @operand = parse_operand2($ins[4]);
	}
	elsif ( $opcode eq '1000' or $opcode eq '1001' # TST, TEQ
		or $opcode eq '1010' or $opcode eq '1011' ) { # CMP, CMN
	    my $isreg = isreg($ins[3]);
	    $rn = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rn must be register at ".strloc($mempos));

	    @operand = parse_operand2($ins[4]);
	}
	else { # All other instructions
	    my $isreg = isreg($ins[3]);
	    $rd = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rd must be register at ".strloc($mempos));

	    $isreg = isreg($ins[4]);
	    $rn = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rn must be register at ".strloc($mempos));

	    @operand = parse_operand2($ins[5].($ins[6]?", $ins[6]":''));
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
	if ( exists($labels{lc $ins[3]}) ) {
	    $out .= dec2bin(($labels{lc $ins[3]}-($mempos+8))/4,24);#+-24-bit offset 23-0
	}
	elsif ( defined(my $x = isimmed($ins[3])) ) {
	    $out .= dec2bin(($x-($mempos+8))/4,24);
	}
	elsif ( defined(isreg($ins[3])) )
	  { throw("For branch to register, use BX/BLX at ".strloc($mempos)) }
	else { throw("Invalid branch address at ".strloc($mempos)) }
    }
    elsif ( $opcode eq '-2' ) { # LDR and STR
	my @operand;
	my $add = 0;
	if ( lc $ins[4] =~ s/\s*([+-])\s*(\d+)\s*$// ) {
	    $add = $1 eq '-' ? -$2 : $2;
	}
	if ( exists($labels{lc $ins[4]}) ) {
	    @operand = parse_operand2('[PC, #'.($labels{lc $ins[4]}-$mempos-8+$add).']');
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
    elsif ( $opcode eq '-5' ) { # LDM and STM
	my $exid = $ins[2];
	$exid .= $ins[0] eq 'LDM'?'L':'S' if $exid =~ /^[EF]/;
	$out .= '100';			# Bits			27-25
	$out .= $extra{$exid} ||'??';	# P and U bits		24-23
	$out .= '0'; # FIXME 		# S bit			22
	$out .= $ins[3] =~ s/!//?1:0;	# W bit			21
	$out .= $ins[0] eq 'LDM'?1:0;	# L bit			20
	$out .= dec2bin(isreg($ins[3]),4);# Rn			19-16
	$out .= ' ';
	my @reglist = ();
	$reglist[$_] = 0 foreach 0..15;
	$ins[4] =~ s/^.*\{(.+?)\}.*$/$1/;
	$ins[4] =~ s/\s*//g;
	foreach my $re ( split(',',$ins[4]) ) {
	    $re =~ /(\w+)(-(\w+))?/;
	    my ($a,$b) = ($1,$3);
	    if ( $2 ) { $reglist[$_] = 1 foreach isreg($a)..isreg($b) }
	    else { $reglist[isreg($a)] = 1 }
	}
	$out .= join('',reverse @reglist); # register list	15-0
    }
    elsif ( $opcode eq '-8' and ( $ins[0] eq 'MUL' or $ins[0] eq 'MLA' ) ) {
	my $rd = dec2bin(isreg($ins[3]),4);
	my $rm = dec2bin(isreg($ins[4]),4);
	my $rs = dec2bin(isreg($ins[5]),4);
	my $rn = dec2bin($ins[0] eq 'MLA' ? isreg($ins[6]) : 0,4);

	$out .= '000000';		# Bits			27-22
	$out .= $ins[0] eq 'MLA'?1 : 0; # Accumulate		21
	$out .= $ins[2] eq 'S'  ?1 : 0; # S Bit
	$out .= $rd.$rn.$rs.'1001'.$rm; # Rd,Rn/SBZ,Rs,1001,Rm	19-0
    }
    elsif ( $opcode eq '-7' ) {
	if ( $ins[0] eq 'MRS' ) {
	    throw("MRS must have SPSR or CPSR at ".strloc($mempos))
	      if $ins[4] ne 'SPSR' and $ins[4] ne 'CPSR';
	    $out .= '00010';		# Bits			27-23
	    $out .= $ins[4] eq 'SPSR' ? # R Bit			22
	      throw("SPSR Not supported at ".strloc($mempos)) : 0;
	    $out .= '001111';		# Bits(x2), SBO(x4)	21-16
	    $out .= dec2bin(isreg($ins[3]),4); # Bits		15-12
	    $out .= '0' x 12;		# SBZ			11-0
	}
	elsif ( $ins[0] eq 'MSR' ) {
	    my $field_mask = '';
	    $ins[3] =~ m/^(SPSR|CPSR)(_([cxsf]+))?$/i or
	      throw("MSR must have SPSR or CPSR at ".strloc($mempos));
	    my $fields = $2?$3:'cxsf';
	    my $cspsr = $1;
	    $field_mask .= $fields =~ m/$_/ ?'1':'0' foreach qw/f s x c/;
	    my @operand = defined(isreg($ins[4])) ?
	      ('0',isreg($ins[4])) : parse_operand2($ins[4]);
	    my $ibit = shift @operand;
	    $out .= '00';		# Bits			27-26
	    $out .= $ibit;		# I Bit			25
	    $out .= '10';		# Bits			24-23
	    $out .= $cspsr eq 'SPSR' ?  # R Bit			22
	      throw("SPSR Not supported at ".strloc($mempos)) : 0;
	    $out .= '10';		# Bits			21-20
	    $out .= $field_mask;	# Field Mask		19-16
	    $out .= '1' x 4;		# SBO			15-12
	    if ( $ibit ) {
		$out .= shift @operand;	# Immediate		11-0
	    }
	    else {
		$out .= '0' x 8;	# SBZ (x4), Bits (x4)	11-8
		$out .= dec2bin(shift(@operand),4); # Rm	3-0
	    }
	}
    }
    elsif ( $opcode eq '-6' ) { # Control Instruction Extension Space (CIES)
	if ( $ins[0] eq 'BKPT' && $ins[1] eq 'AL' ) { # BKPT
	    $out .= '00010010';		# Bits			27-20
	    $out .= '000000000000';	# Immediate		19-8
	    $out .= '0111';		# Bits			7-4
	    $out .= '0000';		# Immediate		3-0
	}
	elsif ( $ins[0] eq 'CLZ' && $ins[1] eq 'AL' ) { # CLZ
	    my $isreg = isreg($ins[3]);
	    my $rd = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rm must be register at ".strloc($mempos));
	    $isreg = isreg($ins[4]);
	    my $rm = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rm must be register at ".strloc($mempos));

	    $out .= '00010110';		# Bits			27-20
	    $out .= '1111';		# SBO			19-16
	    $out .= $rd;		# Rd			19-16
	    $out .= '1111';		# SBO			11-8
	    $out .= '0001';		# Bits			7-4
	    $out .= $rm;		# Rm			3-0
	}
	elsif ( $ins[0] eq 'BX' or $ins[0] eq 'BLX' ) { # BX
	    my $isreg = isreg($ins[3]);
	    my $rm = defined($isreg) ? dec2bin($isreg,4)
	      : throw("Rm must be register at ".strloc($mempos));

	    $out .= '00010010';		# Bits			27-20
	    $out .= '1111'x3;		# SBO x3		19-8
	    $out .= '00';		# Bits			7-6
	    $out .= $ins[0]eq'BLX'?1:0; # L			5
	    $out .= '1';		# Bit			4
	    $out .= $rm;		# Rm			3-0
	}
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
		throw("OUT: Parse error at ".strloc($mempos));
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
    if ( $out =~ m/[!\?]/ ) {
	my $ins = join(' ',@ins[0..2]).' '.join(', ',@ins[3..$#ins]);
	print "Warning: Assembly failed for $ins at $lines[$mempos]\n";
    }
    print $mps.' '.$out,'  ', bin2hex($out), '  ',
      join(' ',@ins[0..2]),' ',join(', ',@ins[3..$#ins]),"\n" if $v >= 1;

    setmem($mempos,bin2dec($out),0);
}

if ( $d ) {
    nprint "Producing debugging information...\n";
    my $debugdata = "$VERSION|";
    my @dbgtemp = ();

    # Dump labels
    vprint "    labels...";
    foreach (keys %labels) {		# Dump labels
	vprint '.';
	push @dbgtemp, "$_;$labels{$_}";
    }
    $debugdata .= join(';',@dbgtemp).'|';
    vprint "done.\n";

    # Dump DCx positions
    vprint "    DCx...";
    $debugdata .= join(';',@memdbg).'|';
    vprint "done.\n";

    # Line Numbers
    vprint "    Line Numbers...";
    $_ ||= '' foreach @lines;
    $debugdata .= join(';',@lines);
    vprint "done.\n";

    my $dbglen;
    if ( $use_zlib ) {
	nprint "Compressing...";
	my $deflated = $debugdata;
	$debugdata = compress($deflated,9);

	if ( length($debugdata) >= length($deflated) ) {
	    nprint "Skipping...";
	    $debugdata = $deflated;
	    $use_zlib = 0;
	}

	$dbglen = length($debugdata);
	$debugdata = '|'.$debugdata while length($debugdata)%4; # ALIGN
	nprint "done.\n";
    }
    elsif ( !$use_zlib ) {
	$debugdata .= '|' while length($debugdata)%4; # ALIGN
	$dbglen = length($debugdata);
    }
    $debugdata .= ($use_zlib?'|ZBG':'|DBG').pack('V',$dbglen);

    $memory .= $debugdata; # FIXME
    nprintf("Produced %d bytes.\n",$dbglen);
}

if ( $OUTPUT ) {
    print $OUTPUT $memory;
    close $OUTPUT;

    # chmod +x ...no seriously.
    my $x=sprintf("%o", (stat $o)[2]);
    $x =~ tr/64/75/;
    $x =~ s/^.*(0[0-7]{3})$/$1/;
    chmod eval $x,$o;

}
elsif ( $mode_x or $mode_d ) {
    $mode = $mode_d ? 2 : 3;
    vprint "\n\n\n";
    goto execute;
}

exit(0); # That's the end of the assembly line.

disassemble:

$mempos = 0;
foreach ( @ARGV ) {
    open INPUT, $_  or throw("Can't open $_: $!");
    binmode INPUT;
    if ( $elf && $#ARGV == 0 ) {
	my $readelf = `readelf --headers "$_"`;
	$readelf =~ m/^\s*Entry point address:\s+0x([0-9A-F]+)\s*$/im
	  or throw("Not in ELF format");
	$startaddr = hex($1);
	#$readelf = `readelf --section-headers "$_"`;
	$readelf =~ m/^\s*(LOAD\s+.+)\s*$/im;
	my @LOAD = split(/\s+/,$1);
	$_ = hex($_) foreach( @LOAD[1..5] );
	seek INPUT, $LOAD[1], 0; # Offset
	read(INPUT, $memory, $LOAD[4], $LOAD[2]) == $LOAD[4]
	  or throw("ELF Read failed");
	setmem($LOAD[2]+$LOAD[5]-4,0,0);
	my $len = $LOAD[5]-$LOAD[4]; # BSS Size
	substr($memory,$LOAD[2]+$LOAD[4],$len,chr(0)x($len));
    }
    elsif ( $elf ) { throw("ELF supported only by one file") }
    else { while ( read INPUT, $memory, 4, $mempos ) { $mempos+= 4 } }
    close INPUT;
}

execute:

my $term = new Term::ReadLine 'ARM Debugger';
my $prompt = '<DB> ';
my $OUT = \*STDOUT;
my $debugnext = 1; # Stop at next instruction
my $defaultc = 0;

my @rlabels = ();
my %cache = ();
my @cachemon = ();
my $cachesize = 0;
my $cachelimit = $cacheless?0:300;
my $tcachelimit = int($cachelimit/3);
my $pcachelimit = int($cachelimit/2);
my %mempos = ();
my $dbgstart = 0x7FFFFFFF;

if ( $d ) {
    if ( $mode == 3 ) {
	$q = 0;
	$v = 0 if $v < 0;
	print "\narm.pl debugger, version $VERSION\n\n";
	print "Try 'perldoc arm.pl' for help\n\n";
    }
    if ( $elf ) {
	if ( $dump_debuginfo ) {
	    print "Use readelf -s to dump debuginfo.\n";
	    exit;
	}
	nprint "Reading ELF debugging information..." if $mode == 3;
	foreach ( `readelf --symbols "$ARGV[0]"` ) {
	    next unless m/^\s*\d+:\s*([0-9a-f]+)\s+\d+\s+(FUNC)\s+\w+\s+\w+\s+\S+\s+($labelmatch)\s*$/;
	    if ( $2 eq 'FUNC' ) {
		$labels{$3} = hex($1);
		$rlabels[hex($1)] = $3;
	    }
	    #print "$3 at 0x$1 is a $2\n";
	}
    }
    else {
	nprint "Searching for debugging information..." if $mode == 3;
	if ( substr($memory,length($memory)-8,4) !~ /^\|([ZD])BG$/ ) {
	    if ( $dump_debuginfo ) {
		print "No debugging information found.\n";
		exit if $dump_debuginfo;
	    }
	    nprint "not found.\n" if $mode == 3;
	}
	else {
	    $use_zlib = 0 if $1 eq 'D';
	    if ( $1 eq 'Z' && !$use_zlib ) {
		print "The debugging information in this file is compressed and cannot be read.\n";
	    }
	    else {
		# $use_zlib is now whether or not the debuginfo is compressed.
		my $dbglen;
		my @debug;
		if ( $use_zlib ) {
		    nprint "decompressing..." if $mode == 3;
		    $dbglen = getmem(length($memory)-4,0);
		    $dbgstart = length($memory)-8-$dbglen;
		    @debug = split('\|',uncompress(substr($memory,$dbgstart)));
		    $dbgstart-- while $dbgstart % 4;
		}
		else {
		    $dbglen = getmem(length($memory)-4,0);
		    $dbgstart = length($memory)-8-$dbglen;
		    @debug = split('\|',substr($memory,$dbgstart));
		}
		if ( $dump_debuginfo ) {
		    print join('|',@debug),'|',$use_zlib?'Z':'D',"BG\n";
		    exit;
		}
		elsif ( $debug[0] == $VERSION ) {
		    print "loaded $dbglen bytes..." if $mode == 3 || $v >= 0;
		    %labels = split(';',$debug[1]);
		    $rlabels[$labels{$_}] = $_ foreach keys %labels;
		    $mempos{$_} = 1 foreach split(';',$debug[2]);
		    @lines = split ';', $debug[3];
		    print "done.\n" if $mode == 3 || $v >= 0;
		}
		elsif ( $mode == 3 || $v >= 0 ) {
		    print "incompatible version $debug[0].\n";
		}
	    }
	}
    }
    print "\n" if $mode == 3 || $v >= 0;
    $OUT = $term->OUT if $term->OUT;
}

reboothere:
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
    printf STDERR "Beginning execution at %s\n",strloc($startaddr) if $v >= 0;
}

$reg[15]=$startaddr+8; # PC, 2 ahead, multiply by four
# Memory allocation
my $memSize = length($memory);
my $pageSize = 0x1000;
my $stackSize = 0xF000 & ~($pageSize-1);
$reg[13]=(($memSize+$pageSize-1) & (~($pageSize-1))) + $stackSize;
my $heapStart = $reg[13];
my $heapBase = $heapStart;
#$reg[13]=length($memory)+0xF000;

# Implement command-line:
# http://uclibc.org/cgi-bin/viewcvs.cgi/trunk/uClibc/libc/sysdeps/linux/arm/crt1.S?rev=&view=markup
#my @arm_argv = qw/echo -n www.busybox.net/;
my $arm_argc = @arm_argv;
my $arg_sp = $reg[13];
my $argv_use_ptr = 1;
my ($argv_list_start, $argv_start);
if ( $argv_use_ptr ) {
    $argv_list_start = $arg_sp+4*3;
    $argv_start = $argv_list_start+4*($arm_argc+1);
}
else {
    $argv_list_start = $arg_sp+4;
    $argv_start = $arg_sp+4*($arm_argc+3);
}
getmem($arg_sp, 4, $arm_argc); $arg_sp += 4; # at SP: ARGC
if ( $argv_use_ptr ) { # Sometimes:
    getmem($arg_sp, 4, $argv_list_start); $arg_sp += 4; # at SP+4: &ARGV
}
foreach my $arg ( @arm_argv ) {
    getmem($argv_list_start, 4, $argv_start);
    foreach my $argchar ( split '', $arg ) {
	getmem($argv_start,1,ord($argchar));
	$argv_start++;
    }
    getmem($argv_start,1,0);
    $argv_start++;
    $argv_start++ while $argv_start % 4;
    $argv_list_start+=4;
    $arg_sp += 4 unless $argv_use_ptr;
}
if ( $argv_use_ptr ) {
    getmem($argv_list_start, 4, 0); # NULL after ARGV
}
else {
    getmem($arg_sp,4,0); $arg_sp += 4; # NULL after ARGV
}
getmem($arg_sp,4,0); $arg_sp += 4; # ENVP
if ( $argv_use_ptr ) { }
else {
    getmem($arg_sp,4,0); $arg_sp += 4; # NULL
}

my $rmeight;
my $died = 0;
my $last = 0;
my $debugnormv = $v;

INSTRUCTION:
while ( $reg[15]<=length($memory)+4 ) {	# Plus Eight. Sigh.
    if ( $d ) {
	$debugnext = 1 if exists $breaks{$reg[15]-8};
	$v = $debugnormv if $debugnext;
    }
    my $rl = $rlabels[$reg[15]-8];
    print "$rl:\n" if $rl && $mode == 2;
    my $check = 1;
    $check = 0 if ($mode == 2 && $o) or ($mode == 3 && $v < 0);

    my %instruction = %{get_instruction($reg[15]-8,1,$check)};

    if ( $mode == 2 ) {
	my $das = disassemble_instruction($reg[15]-8, \%instruction);
	print DIO "\t",$das,"\n"
	  if $o or $q and $das ne '[DEBUG INFO]';
	$reg[15] += 4;
	next;
    }

    my $lineflags = '';

    my $oldpc = $reg[15]; # Save old PC so if it changes we don't increment

    # ARM Debugger
    if ( $debugnext && $d ) {
	my ($listline) = (0);
	my $debugline;
	print "$died\nUse 'q' to quit the debugger.\n\n" if $died;
	while ( $debugnext && (defined($debugline = $term->readline($prompt))||(print("\n\n"),exit(1))) ) {
	    $term->addhistory($debugline) if $debugline =~ /\S/;
	    $debugline =~ s/^\s*//g;
	    $debugline =~ s/\s*$//g;
	    $debugline =~ s/^\s{2,}/ /g;
	    if ( lc $debugline eq 'q' ) { print "\n";exit(1) }
	    elsif( lc $debugline =~ /^r([xsb]?)(\d+)?(\s*=\s*([0-9a-fx]+))?$/){
		if ( $2 && $2 > 15 ) { print "No such register: R$2\n"; next }
		elsif ( $3 && !$2 ) { print "Must specify register\n"; next }
		foreach my $r (defined($2)?$2:0..15) {
		    $reg[$r]||=0;
		    if ( $3 ) {
			if ( $r == 15 && $r % 4 )
			  { print "PC must be word-aligned\n"; next}
			$reg[$r] = substr($4,0,1) eq '0'?oct($4):$4;
		    }
		    if ( $1 eq 'x' or $1 eq 's' ) { # S for OUT compatibility
			printf "R$r = 0x%08x\n",$reg[$r];
		    }
		    elsif ( $1 eq 'b' ) {
			my $rid=$r;
			my $str = pack('V',$reg[$rid]);
			$str =~ s/^\0+(.+)$/$1/;
			printf "R$rid = \"%s\"\n",$str;
		    }
		    else {
			print "R$r = $reg[$r]\n";
		    }
		    if ( $3 ) {
			modreg($r);
			if ( $r == 15 ) { $reg[15]+=4; next INSTRUCTION }
		    }
		}
	    }
	    elsif ( lc $debugline =~ /^w( (\d+|[.\w]+))?$/ ) {
		my $item = $1?debugger_location($2):($reg[15]-8);
		(print(dlerr($item),"\n"),next) if $item < 0;

		if ( $lines[$item] ) { print "$item => $lines[$item]\n" }
		else { print "$item => Unknown location\n" }
	    }
	    elsif ( lc $debugline =~ /^(cc|([cs])psr)\s*$/ ) {
		if ( $1 eq 'cc' or $2 eq 'c' ) {
		    print "N=$N Z=$Z C=$C V=$V\n";
		}
		else { print "SPSR Not supported\n" }
	    }
	    elsif ( lc $debugline =~ /^([bd])( (.+))?$/ ) {
		my $sr = $1 eq 'b'?1:0;
		my $item = $2?debugger_location($3):($reg[15]-8);
		(print(dlerr($item),"\n"),next) if $item < 0;

		$breaks{$item} = 1 if $sr;
		delete $breaks{$item} unless $sr;
		redo INSTRUCTION;
	    }
	    elsif ( lc $debugline =~ /^([vl])( (\d+|[.\w]+))?$/ ) {
		my $view = lc $1 eq 'v'?1:0;

		my $tmp = $2 ? debugger_location($3) : $reg[15]-8;
		(print(dlerr($tmp),"\n"),next) if $tmp < 0;
		my $start = ( (!$2 && $listline)
			      ? $listline
			      : ( $view ? $tmp-8 : $tmp ));
		$start = oct($start) if $start =~ m/^0/;
		if ( $start !~ /^\d+$/ ) { $start = $labels{$start} }

		$start = 0 if $start < 0;
		my $end = $start + ($2 ? 0 : 40);
		$end = length($memory)-4 if $end >= length($memory);
		$start = length($memory)-4 if $start >= length($memory);

		(print(dlerr(-1),"\n"),next) if $start % 4;

		foreach ( my $vadr = $start;$vadr <= $end;$vadr += 4 ) {
		    print "$rlabels[$vadr]:\n" if $rlabels[$vadr];
		    get_instruction($vadr,0,1);
		    $listline = $vadr;
		}
		$listline+=4;
	    }
	    elsif ( lc $debugline =~ /^([qv]?)c$/ or ($debugline eq '' and $defaultc)) {
		if ( $died ) { print "Not running\n";next }
		$debugnext=0;
		$defaultc=1;
		if ( $1 eq 'q' ) { $v = -1 }
		elsif ( $1 eq 'v' ) { $v = 1 }
		last;
	    }
	    elsif ( lc $debugline eq 'n' or ($debugline eq '' and !$defaultc)) {
		if ( $died ) { print "Not running\n";next }
		$debugnext=1;
		$defaultc=0;
		last;
	    }
	    elsif ( $debugline eq 'R' ) {
		print "Resetting...\n";
		goto reboothere;
	    }
	    else { print "Unrecognized command\n" }
	}
    }
    exit(1) if $died;

    # Check conditional
    if ( $instruction{cond} != AL ) {
	$Conditions[$instruction{cond}]() or ($reg[15]+=4,next);
    }
# my $cond = $instruction{cond};
# if ( $cond == AL ) { }                                   # Skip if:
# elsif ( $cond == EQ ) { vprint "EQ: Z=$Z\n"; ($reg[15]+=4,next) if !$Z }
# elsif ( $cond == NE ) { vprint "NE: Z=$Z\n"; ($reg[15]+=4,next) if  $Z }
# elsif ( $cond == CS ) { vprint "CS: C=$C\n"; ($reg[15]+=4,next) if !$C }
# elsif ( $cond == CC ) { vprint "CC: C=$C\n"; ($reg[15]+=4,next) if  $C }
# elsif ( $cond == MI ) { vprint "MI: N=$N\n"; ($reg[15]+=4,next) if !$N }
# elsif ( $cond == PL ) { vprint "PL: N=$N\n"; ($reg[15]+=4,next) if  $N }
# elsif ( $cond == VS ) { vprint "VS: V=$V\n"; ($reg[15]+=4,next) if !$V }
# elsif ( $cond == VC ) { vprint "VC: V=$V\n"; ($reg[15]+=4,next) if  $V }
# elsif ( $cond == HI ) { vprint "HI: C=$C,Z=$Z\n";($reg[15]+=4,next) if !$C ||  $Z }
# elsif ( $cond == LS ) { vprint "LS: C=$C,Z=$Z\n";($reg[15]+=4,next) if  $C && !$Z }
# elsif ( $cond == GE ) { vprint "GE: N=$N,V=$V\n";($reg[15]+=4,next) if  $V !=  $N }
# elsif ( $cond == LT ) { vprint "LT: N=$N,V=$V\n";($reg[15]+=4,next) if  $V ==  $N }
# elsif ( $cond == GT ) { vprint "GT: N=$N,V=$V,Z=$Z\n"; ($reg[15]+=4,next) if $V != $N ||  $Z }
# elsif ( $cond == LE ) { vprint "LE: N=$N,V=$V,Z=$Z\n"; ($reg[15]+=4,next) if $V == $N && !$Z }
# elsif ( $cond == NV ) { $reg[15]+=4; next }
# else {throw("Unsupported condition $conds[$cond] at ".strloc($reg[15]-8))}

    # EXECUTE
    $Executors[$instruction{kind}](\%instruction) or
      throw("Undefined instruction $instruction{kind} at ".strloc($reg[15]-8));

    last if $last;
    $reg[15] += 4;			# Next instruction
}
if ( $mode == 2 ) {
    print STDERR "Disassembly complete.\n" if $v >= 0;
}
else {
    print STDERR "Program complete.\n" if $v >= 0;
}

# Instruction implementations
sub    Assemble_B { }
sub      Decode_B { } # Please see Declassify_B and Declassify_CIES below.
sub     Execute_B {
    my ($instruction) = @_;
    if ( $instruction->{link} ) {
	modreg(14,$reg[15]-4); # PC+8-8+4
	vprint "Link: Return to instruction $reg[14]\n";
    }
    if ( $instruction->{exchange} ) {
	throw("Thumb mode not supported at ".strloc($reg[15]-8))
	  if $reg[15] & 1;
	$reg[15] = $reg[$instruction->{register}] & 0xFFFFFFFE;
    }
    else {
	$reg[15]+=$instruction->{immediate};
    }
    vprint 'Branch: Branching to '.$reg[15]."\n";
    modreg(15); # Hold of for display purposes, etc
    return 1;
}
sub Disassemble_B {
    my ($mempos, $cond, $instruction) = @_;
    my $ins = 'B';
    $ins .= 'L' if $instruction->{link};
    $ins .= 'X' if $instruction->{exchange};
    $ins .= "$cond ";
    if ( $instruction->{exchange} ) {
	$ins .= 'R'.$instruction->{register};
    }
    else {
	my $baddr = $mempos+$instruction->{immediate}+8;
	$ins .= $rlabels[$baddr]||sprintf('&%X',$baddr);
    }
    return $ins;
}

sub    Assemble_DPI { }
sub      Decode_DPI {
    my ($instruction) = @_;
    my $decimal = $instruction->{decimal};
    # Data Processing Instruction
    $instruction->{kind} = DPI;
    $instruction->{opcode} = armbitd($decimal,24,4);
    $instruction->{sbit} = armbitd($decimal,20,1);
    $instruction->{rn} = armbitd($decimal,19,4);
    $instruction->{rd} = armbitd($decimal,15,4);
    if ( armbitd($decimal,25,1) ) {
	my $immed = armbitd($decimal,7,8);
	my $offset = armbitd($decimal,11,4)*2;
	$instruction->{offset} = $offset;
	$instruction->{offsetreg} = 0;
	$instruction->{shifttype} = 3; # ROR
	$instruction->{source} = $immed;
	$instruction->{srcimmed} = 1;
    }
    else {
	$instruction->{source} = armbitd($decimal,3,4);
	$instruction->{srcimmed} = 0;

	# Shift register
	my $oir = armbitd($decimal,4,1);
	$instruction->{shifttype} = armbitd($decimal,6,2) || -1;
	$instruction->{offsetreg} = $oir;
	$instruction->{offset} = armbitd($decimal, 11, $oir?4:5);
    }
    return 1;
}

sub     Execute_DPI { # FIXME Optimize
    my ($instruction) = @_;
    # Operand 2
    my $op2 = $instruction->{srcimmed} ?
      $instruction->{source} : $reg[$instruction->{source}];
    my $offset = $instruction->{offsetreg} ?
      $reg[$instruction->{offset}] : $instruction->{offset};

    ($op2, $fopco) = do_shift($op2,$instruction->{shifttype},
			      $offset,$instruction->{srcimmed});

    my $opcode = $instruction->{opcode};
    my $rn = $instruction->{rn};
    my $rd = $instruction->{rd};
    my $S = $instruction->{sbit};
    return $DPIExecutors[$opcode]($rd,$rn,$op2,$S) or
      	throw("DPI: Unimplemented instruction at ".strloc($reg[15]-8));
}
sub Disassemble_DPI {
    my ($mempos, $cond, $instruction) = @_;
    my $ins = $rdpi[$instruction->{opcode}];
    $ins .= $cond;

    # TST, TEQ, CMP, CMN
    $ins.= 'S' if $instruction->{sbit} and $instruction->{opcode} != 0b1000
      and $instruction->{opcode} != 0b1001
	and $instruction->{opcode} != 0b1010
	  and $instruction->{opcode} != 0b1011;
    $ins .= ' ';

    $ins .= 'R'.$instruction->{rd}.', ' if $instruction->{opcode} != 0b1000
      and $instruction->{opcode} != 0b1001
	and $instruction->{opcode} != 0b1010
	  and $instruction->{opcode} != 0b1011;

    $ins .= 'R'.$instruction->{rn}.', ' if $instruction->{opcode} != 0b1101
      and $instruction->{opcode} != 0b1111; # MOV and MVN

    # Operand 2
    if ( $instruction->{srcimmed} ) {
	$ins .= sprintf('&%X',$instruction->{source});
	if ( $instruction->{offset} ) {
	    if ( $instruction->{srcimmed} ) {
		$ins .= ', '.$instruction->{offset}; # Immediates are ROR
	    }
	    else {
		$ins .= ', '.offset_to_str($instruction->{shifttype},0,$instruction->{offset});
	    }
	}
    }
    else {
	$ins .= 'R'.$instruction->{source};
	if ( $instruction->{offset} || $instruction->{offsetreg} || $instruction->{shifttype} >= 0 ) {
	    $ins .= ', '.offset_to_str($instruction->{shifttype},$instruction->{offsetreg},$instruction->{offset});
	}
    }
    return $ins;
}

sub DPI_AND { modreg($_[0], armand($reg[$_[1]], $_[2]      ,        $_[3]));1}
sub DPI_EOR { modreg($_[0], armxor($reg[$_[1]], $_[2]      ,        $_[3]));1}
sub DPI_SUB { modreg($_[0], armsub($reg[$_[1]], $_[2]      ,     1, $_[3]));1}
sub DPI_RSB { modreg($_[0], armsub($_[2]      , $reg[$_[1]],     1, $_[3]));1}
sub DPI_ADD { modreg($_[0], armadd($reg[$_[1]], $_[2]      ,     0, $_[3]));1}
sub DPI_ADC { modreg($_[0], armadd($reg[$_[1]], $_[2]      ,$C?1:0, $_[3]));1}
sub DPI_SBC { modreg($_[0], armsub($reg[$_[1]], $_[2]      ,     0, $_[3]));1}
sub DPI_RSC { modreg($_[0], armsub($_[2]      , $reg[$_[1]],     0, $_[3]));1}
sub DPI_TST {               armand($reg[$_[1]], $_[2]      ,            1) ;1}
sub DPI_TEQ {               armor ($reg[$_[1]], $_[2]      ,            1) ;1}
sub DPI_CMP {               armsub($reg[$_[1]], $_[2]      ,     1,     1) ;1}
sub DPI_CMN {               armadd($reg[$_[1]], $_[2]      ,     0,     1) ;1}
sub DPI_ORR { modreg($_[0], armor ($reg[$_[1]], $_[2]      ,        $_[3]));1}
sub DPI_MOV { modreg($_[0], armor ($_[2]      , 0          ,        $_[3]));1}
sub DPI_BIC { modreg($_[0], armand($reg[$_[1]],~$_[2]      ,        $_[3]));1}
sub DPI_MVN { modreg($_[0], armor (0          ,~$_[2]      ,        $_[3]));1}

sub    Assemble_MUL { }
sub      Decode_MUL {
    my ($instruction) = @_;
    my $decimal = $instruction->{decimal};
    # MUL, MLA, SMLAL, SMULL, UMLAL, UMULL
    my $longmul = armbitd($decimal,23,1);
    if ( !$longmul and !armbitd($decimal,22,1) ) {
	$instruction->{kind} = MUL;
	$instruction->{accumulate} = armbitd($decimal,21,1);
	$instruction->{sbit} = armbitd($decimal,20,1);
	$instruction->{rd} = armbitd($decimal,19,4);
	$instruction->{rn} = armbitd($decimal,15,4);
	$instruction->{rs} = armbitd($decimal,11,4);
	$instruction->{rm} = armbitd($decimal,3,4);
    }
    elsif ( $longmul ) { # Long multiply
	# Unsupported
	#$instruction->{kind} = CONSTANT;
	#$instruction->{immediate} = $decimal
	return 0;
    }
    else {
	#if ( $died ) { return 0 }
	#else { throw('Unknown multiply at '.strloc($reg[15]-8).': '.
	#	     sprintf('%X',$decimal)) }
	return 0;
    }
    return 1;
}
sub     Execute_MUL {
    my ($instruction) = @_;
    modreg($instruction->{rd}, mul($reg[$instruction->{rm}],$reg[$instruction->{rs}], $instruction->{accumulate}?$reg[$instruction->{rn}]:0, $instruction->{sbit}));
    return 1;
}
sub Disassemble_MUL {
    my ($mempos, $cond,$instruction) = @_;
    my $ins = $instruction->{accumulate}?'MLA':'MUL';
    $ins .= $instruction->{sbit}?"S$cond ":"$cond ";
    $ins .= "R$instruction->{rd}, R$instruction->{rm}, R$instruction->{rs}";
    $ins .= ", R$instruction->{rn}" if $instruction->{accumulate};
    return $ins;
}

sub    Assemble_MRS { }
sub      Decode_MRS {
    my ($instruction) = @_;
    $instruction->{kind} = MRS;
    $instruction->{rbit} = armbitd($instruction->{decimal},22,1);
    $instruction->{rd} = armbitd($instruction->{decimal},15,4);
    return 1;
}
sub     Execute_MRS {
    my ($instruction) = @_;
    throw("SPSR Not supported at ".strloc($mempos)) if $instruction->{rbit};
    modreg($instruction->{rd},compose_psr());
    return 1;
}
sub Disassemble_MRS {
    my ($mempos, $cond,$instruction) = @_;
    return 'MRS'.$cond.' R'.$instruction->{rd}.', '.($instruction->{rbit}?'SPSR':'CPSR');
}

sub    Assemble_MSR { }
sub      Decode_MSR {
    my ($instruction) = @_;
    my $decimal = $instruction->{decimal};
    $instruction->{kind} = MSR;
    $instruction->{rbit} = armbitd($decimal,22,0);
    $instruction->{fields} = armbitd($decimal,19,4);

    # From DPI, but simplified
    if ( armbitd($decimal,25,1) ) {
	my $immed = armbitd($decimal,7,8);
	my $offset = armbitd($decimal,11,4)*2;
	$instruction->{offset} = $offset;
	$instruction->{shifttype} = 3; # ROR
	$instruction->{source} = $immed;
	$instruction->{srcimmed} = 1;
    }
    else {
	$instruction->{offset} = 0;
	$instruction->{shifttype} = 3; # ROR
	$instruction->{source} = armbitd($decimal,3,4);
	$instruction->{srcimmed} = 0;
    }
    return 1;
}
sub     Execute_MSR {
    my ($instruction) = @_;
    throw("SPSR Not supported at ".strloc($mempos)) if $instruction->{rbit};
    my $oldpsr = dec2bin(compose_psr(), 32);
    my $sugpsr = dec2bin($instruction->{srcimmed}
			 ? ror($instruction->{source},$instruction->{offset})
			 : $reg[$instruction->{source}], 32);
    my $newpsr = '';
    my @fields = reverse split('',$instruction->{fields});
    $newpsr .= armbits($fields[3]?$sugpsr:$oldpsr,31,8);
    $newpsr .= armbits($fields[2]?$sugpsr:$oldpsr,23,8);
    $newpsr .= armbits($fields[1]?$sugpsr:$oldpsr,15,8);
    $newpsr .= armbits($fields[0]?$sugpsr:$oldpsr,7,8);
    decompose_psr(bin2dec($newpsr));
    return 1;
}
sub Disassemble_MSR {
    my ($mempos, $cond,$instruction) = @_;

    my $ins = 'MSR'.$cond.' '.($instruction->{rbit}?'SPSR':'CPSR');
    my $fieldstr = '';
    my @fields = reverse split('',$instruction->{fields});
    $fieldstr .= 'c' if $fields[0]; $fieldstr .= 'x' if $fields[1];
    $fieldstr .= 's' if $fields[2]; $fieldstr .= 'f' if $fields[3];
    throw("No fields in MSR at ".strloc($mempos))
      if !$fieldstr;
    $ins .= '_'.$fieldstr unless $fieldstr eq 'cxsf';
    $ins .= ', ';
    if ( $instruction->{srcimmed} ) {
	$ins.=sprintf('&%X',ror($instruction->{source},$instruction->{offset}))
    }
    else { $ins .= 'R'.$instruction->{source} }
    return $ins;
}

sub    Assemble_CLZ { }
sub      Decode_CLZ {
    my ($instruction) = @_;
    $instruction->{kind} = CLZ;
    $instruction->{rm} = armbitd($instruction->{decimal},3,4);
    $instruction->{rd} = armbitd($instruction->{decimal},15,4);
    return 1;
}
sub     Execute_CLZ { # FIXME - Optimize (?)
    my ($instruction) = @_;
    my ($lz) = dec2bin($reg[$instruction->{rm}],32) =~ m/^(0*)/;
    modreg($instruction->{rd},length($lz));
    return 1;
}
sub Disassemble_CLZ {
    my ($mempos, $cond,$instruction) = @_;
    return 'CLZ'.$cond.' R'.$instruction->{rd}.', R'.$instruction->{rm};
}

sub    Assemble_ARMPL { }
sub      Decode_ARMPL {
    my ($instruction) = @_;
    my $opcode = armbitd($instruction->{decimal},19,4);
    if    ( $opcode == 0b0000 ) { $instruction->{format} = DEFAULT }
    elsif ( $opcode == 0b0001 ) { $instruction->{format} = HEX     }
    elsif ( $opcode == 0b0010 ) { $instruction->{format} = BYTES   }
    elsif ( $opcode == 0b0011 ) { $instruction->{format} = IMMED   }
    else  { return 0 }
    $instruction->{kind}   = ARMPL;
    $instruction->{opcode} = OUT;
    if ( $opcode == 0b0011 ) {
	$instruction->{immediate} = bin2dec(armbits($instruction->{binary},15,8),1)
    }
    else { $instruction->{reg} = armbitd($instruction->{decimal},15,4) }
    return 1;
}
sub     Execute_ARMPL {
    my ($instruction) = @_;
    throw("Undefined instruction of type ARMPL at ".strloc($reg[15]-8))
      unless $instruction->{opcode} == OUT;
    if ( defined($instruction->{immediate}) ) {
	print "$instruction->{immediate}\n";
    }
    elsif ( $instruction->{opcode} == OUT ) {
	my $fmt = $instruction->{format};
	foreach ( $instruction->{reg} ) {
	    #,$instruction->{regb},$instruction->{regc}){
	    last unless defined($_);
	    if ( $fmt == HEX ) { printf "R%d = 0x%08x\n",$_,$reg[$_] }
	    elsif ( $fmt == BYTES ) {
		printf "%c",$reg[$_];
	    }
	    else { printf "R%d = %d\n",$_,$reg[$_] }
	}
    }
    return 1;
}
sub Disassemble_ARMPL {
    my ($mempos,$cond,$instruction) = @_;
    throw("Undefined instruction of type ARMPL at ".strloc($reg[15]-8))
      unless $instruction->{opcode} == OUT;
    my $ins = 'OUT';
    if    ( $instruction->{format} == HEX   ) { $ins .= 'S' }
    elsif ( $instruction->{format} == BYTES ) { $ins .= 'B' }
    $ins .= "$cond ";

    if($instruction->{format} == IMMED ) {
	$ins .= sprintf( $instruction->{format} == HEX ? '&%X' : '#%d',
			 $instruction->{immediate});
    }
    else {
	$ins .= 'R'.$instruction->{reg};
    }
    return $ins;
}
sub      Decode_ARMEND { $_[0]->{kind} = ARMEND; $_[0]->{swi} = 0x11 }
sub Disassemble_ARMEND { return 'END'  }
sub      Decode_ARMDIE { $_[0]->{kind} = ARMDIE; $_[0]->{swi} = 0x13 }
sub Disassemble_ARMDIE { return 'DIE'  }
sub      Decode_BKPT   { $_[0]->{kind} = BKPT; $_[0]->{swi} = 0x12 }
sub Disassemble_BKPT   { return 'BKPT' }

sub    Assemble_MEMOR { }
sub      Decode_MEMOR {
    my ($instruction,$ismies) = @_;
    my $decimal = $instruction->{decimal};
    $instruction->{kind} = MEMOR;
    $instruction->{isload} = armbitd($decimal,20,1);
    $instruction->{rd} = armbitd($decimal,15,4);
    $instruction->{rn} = armbitd($decimal,19,4);
    $instruction->{positive} = armbitd($decimal,23,1);
    if ( $ismies ) { # Signed byte, double and half word access
	my $mieskind=(armbitd($decimal,20,1)<<2)|armbitd($decimal,6,2);
	if ( $mieskind == 0b010 or $mieskind == 0b011 ) {
	    #if ( $died or !$check_validity ) { return \%default }
	    #else { throw('Doubleword not supported at '.
	    #strloc($reg[15]-8). ': ' . sprintf('%X',$decimal)) }
	    return 0;
	}

	$instruction->{byte} = armbitd($decimal,5,1) ? 2 : 1;
	$instruction->{byte} *= -1 if armbitd($decimal,6,1);

	if ( armbitd($decimal,22,1) ) { # Immediate offset
	    $instruction->{offset} =
	      (armbitd($decimal,11,4)<<4) | armbitd($decimal, 3,4);
	    $instruction->{offsetimmed} = 1;
	}
	else {			# Register offset
	    $instruction->{offset} = armbitd($decimal,3,4);
	    $instruction->{offsetimmed} = 0;
	    $instruction->{shifttype} = -1; # No shift
	    $instruction->{offsetshift} = 0;
	}
    }
    else { # Unsigned byte/word access
	$instruction->{byte} = armbitd($decimal,22,1);
	if ( !armbitd($decimal,25,1) ) { # Immediate offset
	    $instruction->{offset} = armbitd($decimal,11,12,0);
	    $instruction->{offsetimmed} = 1;
	}
	else {			# Register offset
	    $instruction->{offset} = armbitd($decimal,3,4);
	    $instruction->{offsetimmed} = 0;
	    $instruction->{shifttype} = armbitd($decimal,6,2)||-1;
	    $instruction->{offsetshift} = armbitd($decimal,11,5);
	}
    }

    # Various unsupported strangeness
    my $P = armbitd($decimal,24,1);
    my $W = armbitd($decimal,21,1);
    if ( $W && !$P ) {
	#if ( $died ) { return \%default }
	#else { throw("LDR/STR T mode is not supported at ".
	#	     strloc($reg[15]-8)) if $check_validity }
	return 0;
    }
    elsif ( $W && $P ) { # Pre-indexed
	$instruction->{update} = -1;
    }
    elsif ( !$P ) { # Post-indexed
	$instruction->{update} = 1;
    }
    elsif ( $P && !$W ) { $instruction->{update} = 0 }
    $instruction->{update} ||= 0;
    return 1;
}
sub     Execute_MEMOR {
    my ($instruction) = @_;
    my $addr = $reg[$instruction->{rn}];
    my $myoffset;
    if ( $instruction->{offsetimmed} ) { $myoffset = $instruction->{offset} }
    else {
	my $temp;
	($myoffset,$temp) = do_shift($reg[$instruction->{offset}],$instruction->{shifttype},$instruction->{offsetshift},0,0);
    }
    if ( $instruction->{update} <= 0 ) { # Pre-indexed addressing
	$addr += $myoffset*($instruction->{positive}?1:-1);
    }

    if ( $instruction->{isload} ) {
	modreg($instruction->{rd}, getmem($addr,$instruction->{byte}));
    }
    else {
	setmem($addr,$reg[$instruction->{rd}],$instruction->{byte});
    }

    if ( $instruction->{update} != 0 ) { # Writeback
	$addr += $myoffset*($instruction->{positive}?1:-1)
	  if $instruction->{update} > 0;
	modreg($instruction->{rn},$addr);
	vprint "Writing $addr to R$instruction->{rn}\n";
    }
    return 1;
}
sub Disassemble_MEMOR {
    my ($mempos, $cond, $instruction) = @_;
    my $ins = $instruction->{isload}?'LDR':'STR';
    $ins .= $cond;
    $ins .= 'S' if $instruction->{byte} < 0;
    $ins .= 'H' if abs($instruction->{byte}) == 2;
    $ins .= 'B' if abs($instruction->{byte}) == 1;
    $ins .= " R$instruction->{rd}, [R$instruction->{rn}";
    $ins .= ']' if $instruction->{update} > 0;
    $ins .= ', ';
    $ins .= '#' if $instruction->{offsetimmed};
    $ins .= '-' unless $instruction->{positive};
    $ins .= 'R' unless $instruction->{offsetimmed};
    $ins .= $instruction->{offset};
    $ins .= ', '.offset_to_str($instruction->{shifttype},1,$instruction->{offsetshift}) if !$instruction->{offsetimmed} && $instruction->{shifttype} > 0 && $instruction->{offsetshift} > 0;
    $ins .= ']' if $instruction->{update} <= 0;
    $ins .= '!' if $instruction->{update} < 0;
    #$ins .= ' FIXME';
    return $ins;
}

sub    Assemble_LDM { }
sub      Decode_LDM {
    my ($instruction) = @_;
    my $decimal = $instruction->{decimal};
    $instruction->{kind} = LDM;
    $instruction->{isload} = armbitd($decimal,20,1);
    $instruction->{rn} = armbitd($decimal,19,4);
    $instruction->{pbit} = armbitd($decimal,24,1);
    $instruction->{ubit} = armbitd($decimal,23,1);
    $instruction->{update} = armbitd($decimal,21,1); # W bit
    my $r = armbitd($instruction->{decimal},15,16);
    my $i = 0;
    my $mask = 1<<$i;
    my @registers = ();
    while ( $i <= 15 ) {
	if ( $r & $mask ) {
	    push @registers, $i
	}
	$i++;
	$mask <<= 1;
    }
    #foreach ( reverse split('',armbits($instruction->{binary},15,16));
    $instruction->{registers} = \@registers;
    return 1;
}
sub     Execute_LDM {
    my ($instruction) = @_;
    my $start_address = 0;
    my $end_address = 0;
    my $rn = $reg[$instruction->{rn}];
    my @registers = @{$instruction->{registers}};#();
    #for (my $i=0;$i <scalar(@{$instruction->{registers}});$i++) {
    #  push @registers, $i if $instruction->{registers}[$i]
    #}
    my $length = scalar(@registers) * 4;
    if ( !$instruction->{pbit} && !$instruction->{ubit} ) { # DA
	$start_address = $rn - $length + 4;
	$end_address = $rn;
	$rn -= $length;
    }
    elsif ( !$instruction->{pbit} && $instruction->{ubit} ) { # IA
	$start_address = $rn;
	$end_address = $rn + $length - 4;
	$rn += $length if $instruction->{update};
    }
    elsif ( $instruction->{pbit} && !$instruction->{ubit} ) { # DB
	$start_address = $rn - $length;
	$end_address = $rn - 4;
	$rn -= $length;
    }
    elsif ( $instruction->{pbit} && $instruction->{ubit} ) { # IB
	$start_address = $rn + 4;
	$end_address = $rn + $length;
	$rn += $length;
    }
    else { throw("Invalid P and U bits  at ".strloc($reg[15]-8)) }

    for(my $addr=$start_address; $addr<=$end_address; $addr+=4) {
	my $num = shift @registers;
	if ( $instruction->{isload} ) {
	    $reg[$num] = getmem($addr,0);
	    modreg($num);
	    vprint "Loading register R$num\n";
	}
	else {
	    setmem($addr,$reg[$num],0);
	    vprint "Storing register R$num\n";
	}
    }
    if ( $instruction->{update} ) {
	modreg($instruction->{rn}, $rn);
	vprint "Updating base register\n";
    }
    return 1;
}
sub Disassemble_LDM {
    my ($mempos, $cond, $instruction) = @_;
    my $ins = $instruction->{isload}?'LDM':'STM';
    $ins .= $cond;
    foreach ( keys %extra ) {
	next if m/^[^DI]/; # FIXME -v
	$ins .= $_ if $extra{$_} eq $instruction->{pbit}.$instruction->{ubit};
    }
    $ins .= " R$instruction->{rn}";
    $ins .= '!' if $instruction->{update};
    $ins .= ', {';
    my @reglist = ();
    my $i=0;
    foreach ( @{$instruction->{registers}} ) {
	if ( $i > 0 and $instruction->{registers}[$i-1] == $_-1 ) {
	    $reglist[-1] =~ s/\s*-\s*R\d+|$/-R$_/;
	}
	else { push @reglist, "R$_" }
	$i++;
    }
    $ins .= join(', ',@reglist).'}'; # Does not support ^.
    return $ins;
}

sub    Assemble_SWI { }
sub      Decode_SWI {
    my ($instruction) = @_;
    $instruction->{kind} = SWI;
    $instruction->{swi} = armbitd($instruction->{decimal},23,24);
    return 1;
}
sub     Execute_SWI {
    my ($instruction) = @_;
    nprintf "SWI\t%8d\t%06X\n", $instruction->{swi}, $instruction->{swi};

    $SWI{$instruction->{swi}} ||=
      sub {throw(sprintf("Unknown SWI %X, terminating at %s",$_[0],strloc($reg[15]-8)))};
    return $SWI{$instruction->{swi}}($instruction->{swi});
}
sub Disassemble_SWI {
    my ($mempos, $cond,$instruction) = @_;
    return sprintf('SWI%s &%06X',$cond,$instruction->{swi});
}
sub SWI_OS_Write0 { printf "%c", $reg[0]; return 1 }
sub SWI_OS_Exit   { $last = 1; return 1 }
sub SWI_ARMSIM_BKPT {
    print "BKPT - Entering the debugger.\n";
    $debugnext = 1;
    if ( !$d ) {
      $debugnormv = 0 if $v <= 0; $d = 1;
      $OUT = $term->OUT if $term->OUT;
    }
    return 1;
}
sub SWI_ARMSIM_DIE { throw("Died at ".strloc($reg[15]-8)) }
sub SWI_ARMSIM_GETC {
    throw("Term::ReadKey is not available at ".strloc($reg[15]-8))
      unless $allow_readkey;
    ReadMode(4);
    my $c = ReadKey(0);
    ReadMode(0);
    throw("EOF\n") unless defined($c);
    throw("^C\n") if -t STDIN && $c eq "\003";
    $reg[0] = ord($c);
    printf "%c",$reg[0];
}
sub SWI_sys_exit  {
    if ( $reg[0] == 0 ) { $last = 1 }
    else {throw('Died (via SWI) at '.strloc($reg[15]-8).' (rc='.$reg[0].')')}
    return 1;
}
sub SWI_sys_ioctl {
    printf "Sys_ioctl(fd=%d, cmd=%d, arg=%x)\n", $reg[0], $reg[1], $reg[2]
      if $v >= 0;
    my $cmd = $reg[1];
    my $cmdNR = $cmd & 0xff;
    my $cmdType = ($cmd >> 8) & 0xff;
    my $cmdSize = ($cmd >> 16) & 0x3fff;
    my $cmdDir = ($cmd >> 30) & 0x3;
    if ($cmdType == 0x54) {           # various terminal cmds: ord('T')==0x54
      if ($cmdNR == 0x01) {           # TCGETS
          print "Doing TCGETS\n" if $v >= 0;
          my $termios = $reg[2];      # arg is (struct termios *)
          memset($termios, 0, 4*4+5); # clear part of output structure
      }
    } elsif ($cmdType == 0x89) {      # various socket cmds
    }
    $reg[0] = 0;                      # result
    return 1;
}
sub SWI_sys_mmap {
    my $args = $reg[0];
    my ($start, $length, $prot, $flags, $fd, $offset) =
      map getmem($args+$_*4), (0..5);
    printf("Sys_mmap(args@%x: start=%x, length=%d, prot=%x,"
          . " flags=%x, fd=%d, offset=%x)\n",
         $reg[0], $start, $length, $prot, $flags, $fd, $offset)
      if $v >= 0;
    #define MAP_ANONYMOUS 0x20          /* don't use a file */
    if ($flags & 0x20) {
      # Anonymous mapping, just means: "give me some memory"
      if ($length > 1e6) {
          $reg[0] = -12;              # ENOMEM
      } else {
          $length = ($length + $pageSize - 1) & ~($pageSize-1); # round up
          my $addr = $heapBase;
          $heapBase += $length;
          printf "Sys_mmap: allocating %x bytes, heapSize = %dKB\n",
              $length, ($heapBase - $heapStart)/1024
                  if $v >= 0;
          $reg[0] = $addr;
      }
    } else {
      # Don't support mapping files
      $reg[0] = -22;                  # EINVAL
    }
    return 1;
}
# Fetch null-terminated string from memory
sub getstr {
    my $ptr = shift;
    my $str = '';
    while (my $c = getmem($ptr++, 1)) {
      $str .= chr($c);
    }
    $str;
}
sub SWI_sys_open {
    my $pathP = $reg[0];
    my $path = getstr($pathP);
    printf "Sys_open(path=%s, flags=%x, mode=%o)\n", $path, $reg[1], $reg[2];
    $reg[0]=5;                                # pick a file descriptor
    1;
}
sub SWI_sys_read {
    printf "Sys_read(fd=%d, buf=%x, count=%d)\n", $reg[0], $reg[1], $reg[2];
    $reg[0]=$reg[2];                          # return expected quantity
    1;
}
sub SWI_sys_write {
    my $path = getstr($reg[1]);
    if ( $v >= 0 || $reg[0] > 2 ) {
	printf "Sys_write(fd=%d, buf=%x, count=%d)\t%s\n", $reg[0], $reg[1], $reg[2],$path;
    }
    else { print $path }
    $reg[0]=$reg[2];                          # return expected quantity
    1;
}
sub SWI_sys_close {
    printf "Sys_close(fd=%d)\n", $reg[0];
    $reg[0]=0;
    1;
}
sub SWI_sys_time {
    printf "Sys_time(timeP=%x)\n", $reg[0];
    setmem($reg[0], time, 4);
    $reg[0]=0;
    1;
}
sub SWI_sys_getpid { print "GetPID\n"; $reg[0] = 1; return 1 }
sub SWI_sys_getuid { $reg[0] = 0; return 1 }
sub SWI_sys_getgid { $reg[0] = 0; return 1 }

sub Condition_EQ {  $Z }
sub Condition_NE { !$Z }
sub Condition_CS {  $C }
sub Condition_CC { !$C }
sub Condition_MI {  $N }
sub Condition_PL { !$N }
sub Condition_VS {  $V }
sub Condition_VC { !$V }
sub Condition_HI {  $C && !$Z }
sub Condition_LS { !$C ||  $Z }
sub Condition_GE {  $N ==  $V }
sub Condition_LT {  $N !=  $V }
sub Condition_GT { !$Z && ( $N == $V ) }
sub Condition_LE {  $Z || ( $N != $V ) }
sub Condition_AL { 1 }
sub Condition_NV { 0 }

# Declassifiers help determine which decoder to use
sub Declassify_DPI0 {
    my ($instruction) = @_;
    my $decimal = $instruction->{decimal};
    if ( armbitd($decimal,7,1) && armbitd($decimal,4,1) ) {
	return Declassify_MIES($instruction);
    }
    if ( armbitd($decimal,24,2) == 0b10 && !armbitd($decimal,20,1) ) {
	return Declassify_CIES($instruction);
    }
    return Decode_DPI($instruction);
}
sub Declassify_MIES {
    my ($instruction) = @_;
    my $decimal = $instruction->{decimal};
    if ( armbitd($decimal,7,4) == 0b1001 && !armbitd($decimal,24,1) ) {
	return Decode_MUL($instruction); # Not actually MIES
    }
    my $miesop = (armbitd($decimal,20,1)<<2)+armbitd($decimal,6,2);
    if ( armbitd($decimal,24,1) && !armbitd($decimal,23,1) && !armbitd($decimal,21,1) && $miesop == 0 ) {
	# SWP and SWPB
	#if ( $died or !$check_validity ) { return \%default }
	#else { throw('SWP and SWPB not supported at '.
	#	     strloc($reg[15]-8). ': ' . sprintf('%X',$decimal)) }
	return 0;
    }
    return 0 unless armbitd($decimal,6,2);
    return Decode_MEMOR($instruction,1);
}
sub Declassify_CIES {
    my $decimal = $_[0]->{decimal};
    # Control Instruction Extension Space (CIES)
    my $op1 = armbitd($decimal,22,2);
    my $op2 = armbitd($decimal,7,4);
    if    (!$op2 && (!$op1 || $op1 == 0b10)) { return Decode_MRS(@_) }
    elsif (!$op2 &&  armbitd($decimal,21,1)) { return Decode_MSR(@_) }#Reg MSR
    elsif ( $op1 == 1 && $op2 == 0b0111 && $_[0]->{cond} == AL ) {
	return Decode_BKPT(@_);
    }
    elsif ( $op1 == 1 && ( $op2 == 1 or $op2 == 0b0011 ) ) {
	# BX, BLX (Branch and Exchange)
	my ($instruction) = @_;
	$instruction->{kind} = B;
	$instruction->{link} = armbitd($decimal,5,1);
	$instruction->{register} = armbitd($decimal,3,4);
	$instruction->{exchange} = 1;
	return 1;
    }
    elsif ( $op1 == 0b11 && $op2 ==0b0001 ) { return Decode_CLZ(@_) }
    else {
	#if ( $died or !$check_validity ) { return \%default }
	#else { throw('Undefined CIES instruction at '.
	#	     strloc($reg[15]-8). ': ' . sprintf('%X',$decimal)) }
	return 0;
    }
}
sub Declassify_DPI1 {
    my ($instruction) = @_;
    my $decimal = $instruction->{decimal};
    if ( armbitd($decimal,24,2) == 0b10 && !armbitd($decimal,20,1) ) {
	# Immediate MSR
	return Decode_MSR($instruction) if armbitd($decimal,21,1);
	return 0; # Undefined instruction
    }
    return Decode_DPI($instruction);
}
sub Declassify_LDRI { return Decode_MEMOR(@_) }
sub Declassify_LDRR {
    return armbitd($_[0]->{decimal},4,1)
      ? Declassify_ARMPL(@_) : Decode_MEMOR(@_);
}
sub Declassify_LDM  { return Decode_LDM(@_) }
sub Declassify_B    {
    my ($instruction) = @_;
    $instruction->{kind} = B;
    $instruction->{link} = armbitd($instruction->{decimal},24,1);
    my $immediate = armbitd($instruction->{decimal},23,24);
    if ( $immediate & (1<<23) ) {
	$immediate -= 1<<24;
    }
    $instruction->{immediate} = ($immediate << 2);
    $instruction->{exchange} = 0;
    return $instruction;
}
sub Declassify_CPLS { return 0 }
sub Declassify_CPSI {
    return $DeclassifyCPSI[armbitd($_[0]->{decimal},24,1)](@_);
}
sub Declassify_ARMPL {
    my ($instruction) = @_;
    my $decimal = $instruction->{decimal};
    return 0 unless ( armbitd($decimal,24,5) == 0b11111 )
      && ( armbitd($decimal,7,4) == 0xF );
    my $opcode = armbitd($decimal,19,4);
    return $DeclassifyARMPL[$opcode](@_);
}

sub decode_instruction {
    my ($binary,$decimal,$check_validity) = @_;

    my $kind = armbitd($decimal,27,3);

    my %instruction = ( binary => $binary, decimal => $decimal );
    $instruction{cond} = armbitd($decimal,31,4)&0xF;
    my %default = %instruction; $default{kind} = UNKNOWN;

    my $rv = $DeclassifyByKind[$kind](\%instruction);
    return \%instruction if $rv;
    throw(sprintf('Instruction decoding failed for %s: %X',strloc($reg[15]-8),
		  $decimal)) if $check_validity;
    return \%default;
}

sub disassemble_instruction {
    my ($mempos,$instruction) = @_;

    my $cond = $conds[$instruction->{cond}];
    $cond = '' if $cond eq $conds[AL];
    if ( $d && $mempos >= $dbgstart ) { return '[DEBUG INFO]' }

    return ($Disassemblers[exists $mempos{$mempos} ? CONSTANT
			   : $instruction->{kind}]($mempos,$cond,$instruction)
	    or 'UNKNOWN');
}

sub fetch_instruction {
    my ($instruction,$check_validity) = @_;
    my $iref = decode_instruction(dec2bin($instruction,32),
				 $instruction,$check_validity);

    # Cache management
    if ( $cachelimit ) {
	$cache{$instruction} = $iref;
	$cache{$instruction}{usage} = 0;
	$cachesize++;
	unshift @cachemon, $instruction;
	if ( $#cachemon > $tcachelimit ) {
	    my $last = pop @cachemon;
	    unless ( $cache{$last}{usage} ) {
		delete $cache{$last};
		$cachesize--;
	    }
	}
	if ( $cachesize > $cachelimit ) {
	    my @cached = sort { $cache{$a}{usage} <=> $cache{$b}{usage} }
	      keys %cache;
	    delete $cache{$_} foreach @cached[0..($pcachelimit-1)];
	    $cachesize -= $pcachelimit;
	}
    }
    return $iref;
}

sub get_instruction {
    my ($addr,$check_validity,$print_out) = @_;

    my $instruction = getword($addr);
    my $fromcache = 0;
    my $iref;

    if ( exists $cache{$instruction} ) {
	$iref = $cache{$instruction};
	$iref->{usage}++;
	$fromcache = 1;
    }
    else {
	$check_validity = 0 if $mode_d || $addr >= $dbgstart;
	$iref = fetch_instruction($instruction,$check_validity)
    }

    return $iref unless $print_out;

    my %instruction = %$iref;
    my $binary = $instruction{binary};
    $check_validity = 0 if $mode_d || $addr >= $dbgstart;
    if ( $mode == 2 and ( $v < 0 or $o ) and $check_validity ) {
	print DIO "\t",disassemble_instruction($addr, \%instruction),"\n";
    }
    if ( $v >= 0 ) {
	my $linetype = exists($breaks{$addr})?'b':($fromcache?'c':'');
	my $active = (($reg[15]-8==$addr)&&(!$d||($d and $debugnext)))?'>':'';
	my $flags = ($linetype||$active||' ').($active||' ');

	my $mps = sprintf '%X:', $addr;
	$mps .= ' 'x(4-length($mps));
	my $os = $mps." $flags$binary   ".sprintf('%08X',$instruction);
	$os .= "  ".disassemble_instruction($addr, \%instruction)."\n";
	if ( $mode == 2 ) { print $os }
	else { print STDERR $os }
    }
    return $iref;
}

sub offset_to_str {
    my ($kind,$isreg,$offset) = @_;
    my $offsetstra = ($isreg?'R':'#').$offset;
    my $offsetstrb = $isreg?$offsetstra:('#'.($offset == 0?32:$offset));
    if    ( $kind == -1) { return "LSL $offsetstra" }
    elsif ( $kind == 1 ) { return "LSR $offsetstrb" }
    elsif ( $kind == 2 ) { return "ASR $offsetstrb" }
    elsif ( $kind == 3 && !$isreg && $offset == 0 ) { return 'RRX' }
    elsif ( $kind == 3 ) { return "ROR $offsetstra" }
    else { throw("Bad Offset Type") }
}

sub throw {
    my ($msg) = @_;
    my @caller = caller;

    # To prevent infinite loops, e.g. PC misaligned, load instruction,
    # die, enter debugger, load instruction, die, enter debugger...
    if ( $died ) { return }
    elsif ( $d && $mode == 3 ) {
	$debugnext = 1;
	$died = $msg;
	{ no warnings; redo INSTRUCTION } # They don't like this
	return;
    }
    else {
	die $msg.($msg !~ /\n$/ ? " at $caller[1] line $caller[2].\n":'');
    }
}

sub isreg {
    my ($pos) = @_;
    return $regalias{uc $pos} if exists $regalias{uc $pos};
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

	if ( $fop =~ s/\+// ) { }
	elsif ( $fop =~ s/-// ) { $U = 0 }

	# Bug - For Addr Mode 2, shifting expects another register

	#vprint "FOP: $1\n";
	my $regmatch = join('|',keys %regalias);
	if ( $fop =~ /^([#&][+-]?[\da-fx]+|$regmatch)$/i ) {
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
	elsif ( $fop =~ /^($fopmatch)(\s+(R\d+|[#&][0-9a-fx]+))?$/i ) {
	    my $fopkind = uc $1;
	    my $fopby = 0;
	    my $o = $fopkind eq 'RRX'?'#0':$3;
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
		$offset = 0 if $fopby == 32 && isimmed($o);
		#$_ = $_ >> $fopby;
	    }
	    elsif ( $fopkind eq 'ASR' ) { # Arithmetic Right
		# $a & 0x80000000 to get high bit then shift then or
		$offsetshift = 2;
		$offset = $fopby;
		$offset = 0 if $fopby == 32 && isimmed($o);
	    }
	    elsif ( $fopkind eq 'ROR' ) { # Rotate Right
		$offsetshift = 3;
		$offset = $fopby;
	    }
	    elsif ( $fopkind eq 'RRX' ) {
		$offsetshift = 3;
		$offset = 0;
	    }
	    #print "FOP $fopkind by $fopby\n";
	}
	elsif ( defined(isimmed($val)) ) { $offset = $fop+0 }
	else { throw("Bad FOP - got through the parser but not the translator? $fop") }
    }

    if ( $brackets ) {			# Addressing mode 2
	my ($I,$P,$W) = (1,0,0);
	if ( $offsetshift ) {
	    if ( $offset or 1 ) {
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
	if ( defined($f = isreg($val)) ) {
	    if ( $offset or $offsetreg or 1 ) {
		$out = ' '.dec2bin($offset+0,($offsetreg?4:5));
		if   ( $offsetshift == -1 ) { $out .= $offsetreg? '0001':'000'}
		elsif ( $offsetshift == 0 ) { $out .= $offsetreg? '0000':'000'}
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
	elsif ( defined($f = isimmed($val)) ) {
	    $I='1';
	    my $shift = $offset+0;
	    my $test = $f;
	    while ( !$offset && $shift < 32 ) {
		last if ($test&0xFFFFFF00) == 0;
		$shift+=2;
		$test = ror($test,2);
	    }
	    #print "$f rotated by $shift\n";
	    $f = $test;
	    $out = ' '.($shift == 0?'0000':dec2bin(($offset?$offset:(32-$shift))/2,4));
	    $out .= dec2bin($f,8);# shifter_operand 11-0
	}
	else { $out = ' ????????????'; }
	return ($I,$out);
    }
}

sub isimmed {
    my ($val) = @_;
    $val =~ s/([+-])#/#$1/; #	s#DDD	#sDDD
    $val =~ s/&([+-])/$1&/; #	&sXXX	s&XXX
    $val =~ s/#([+-]?)0x/$1&/;#	#s0xXXX	s&XXX
    if ( $val =~ /^#([+-]?\d+)$/ ) { # Numbers
	return $1+0;
    }
    elsif ( $val =~ /^(?:&|#0x)([\dA-F]+)$/i ) { # Hex Numbers
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
    my $result = ($a+$b+$ci) & 0xffffffff;
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
    use bytes;
    my ($index,$bytes,$write) = @_;
    $bytes = 4 unless $bytes;
    my $signed = 0; if ( $bytes < 0 ) { $signed = 1; $bytes = -$bytes }
    throw("Access at incorrect alignment $index/$bytes".'b at '.
	  strloc($reg[15]-8)) if $index%$bytes;
    throw("Access at negative address $index at ".strloc($reg[15]-8))
      if $index < 0;
    $memory .= chr(0)x($index-length($memory)+8) if length($memory) < $index+4;

    if ( defined($write) ) { # Write to memory
	if ( $d && $mode == 3 && exists($breaks{$index-($index%4)}) ) {
	    printf "Modifed word at 0x%08X at %s\n",$index,strloc($reg[15]-8);
	    printf "  Old data 0x%08X\n", getmem($index-($index%4),0);
	    $debugnext = 1;
	}
	if    ( $bytes == 1 ) {substr($memory,$index,$bytes, chr(0xFF&$write))}
	elsif ( $bytes == 2 ) {substr($memory,$index,$bytes,pack('v', $write))}
	elsif ( $bytes == 4 ) {substr($memory,$index,$bytes,pack('V', $write))}
	else { throw("Can't access memory on $bytes-byte alignment at ".
		     strloc($reg[15]-8)) }
	return;
    }

    # Read from memory
    my $result = 0;
    if ( $bytes == 1 ) { $result = ord(substr($memory,$index,1)) }
    elsif ( $bytes == 2 ) { $result = unpack('v',substr($memory,$index,2)) }
    elsif ( $bytes == 4 ) { $result = unpack('V',substr($memory,$index,4)) }
    else { throw("Can't access memory on $bytes-byte alignment at ".
	  strloc($reg[15]-8)) }

    return $result if !$signed || !($result & (1<<($bytes*8-1)));
    return ($result | 0xFFFFFF00) if $bytes == 1;
    return ($result | 0xFFFF0000) if $bytes == 2;
    throw("Invalid signed size: $bytes at ".strloc($reg[15]-8));
}

sub setmem { return getmem($_[0],$_[2],$_[1]) }

sub getword { # Highly optimized getmem(), for unsigned words only
    my ($index) = @_;
    throw("Access at incorrect alignment $index/w at ".strloc($reg[15]-8))
      if $index & 3;
    throw("Access at negative address $index at ".strloc($reg[15]-8))
      if $index < 0;
    $memory .= chr(0)x($index-length($memory)+8) if length($memory) < $index+4;

    # Read from memory
    return unpack('V',substr($memory,$index,4));
}

sub makechar {
    my ($ec) = @_;
    $ec =~ s/^\\// or return $ec;
    return chr(oct($ec)) if $ec =~ m/^\d+$/;
    return chr(hex($1)) if $ec =~ m/^x(\d+)$/;
    return chr(7) if uc $ec eq 'A';
    return chr(8) if uc $ec eq 'B';
    return chr(9) if uc $ec eq 'T';
    return chr(10) if uc $ec eq 'N';
    return chr(11) if uc $ec eq 'V';
    return chr(12) if uc $ec eq 'F';
    return chr(13) if uc $ec eq 'R';
    return chr(27) if uc $ec eq 'E';
    return '';
}

sub MungeString {			# Munge string for use in DCB
    my ($tmp) = @_;
    vprint "Munging string $tmp\n";
    $tmp =~ s/(\\(?:\d+|.))/makechar($1)/ge;
    my $out = '';
    foreach(split('',$tmp)) {
	$out.='#'.ord($_).', ';
    }
    $out =~ s/\,\s*$//g;
    vprint "  $out\n";
    return $out;
}

sub modreg {				# Do any special things that need to
    my ($reg,$newval) = @_;		# be done when a register has been
					# modified
    $reg[$reg] = $newval if defined($newval);
    if ( $reg == 15 ) { $reg[15]+=4 }
}

# Various and sundry type conversions
sub dec2bin { # From http://www.infocopter.com/perl/character-encoding.htm
    my ($dec,$bits) = @_;
    my $mb = $bits -1;
    my $bin = sprintf("%032b", $dec);
    my ($a,$b,$c) = $bin =~ m/^(0*|1*)([01])([01]{$mb})$/;
    my @caller = caller;
    throw("Value too large: $dec (".strloc($reg[15]?($reg[15]-8):$mempos).')')
      unless defined $b;
    $bin = "$b$c";
    #my $padding = 0;
    #print "$dec\t$bin\t".bin2dec($bin)."\n";
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
    my ($bin,$signed) = @_;
    $bin =~ s/\s//g;
    $bin = substr($bin,2) if substr($bin,0,2) eq '0b';
    if ( $bin !~ /[^01]/ ) {
	my $e = eval('0b'.$bin);
	if ( $signed && substr($bin,0,1) eq '1' ) {
	    return $e-2**length($bin);
	}
	return $e;
    }
    return 0;
}

sub armbits { # Like substr, except taking $_[1] as 31-0. For convenient
    return substr($_[0],31-$_[1],$_[2]); # compatibility with DDI-0100E
}
sub armbitd { # Like armbits, but operating on actual numbers
    my ($x,$start,$len,$signed) = @_;
    my $mask = 2**$len-1;
    $len--;
    $mask <<= ($start-$len);
    #my $fmask = 0;
    #for ( my $sl = $len;$sl>=0;$sl--) {
    #$fmask |= 1<<($start-$sl);
    #}
    throw("Signed unsupported by armbitd") if $signed;
    return ($x&$mask) >> ($start-$len);
}

sub debugger_location { # Parse a debugger "Location".
    my ($loc) = @_;
    $loc =~ s/^\s*|\s*$//g;
    if ( exists($labels{lc $loc}) ) { # Labels
	return $labels{lc $loc};
    }
    elsif ( $loc =~ m/^0d(\d+)/i ) { # Decimal
	my $addr = $1+0;
	return -1 if $addr % 4;
	return $addr;
    }
    elsif ( $loc =~ m/^(0)?[0-9a-f]+/i ) { # Octal/Hex/Binary
	my $addr = ($1||'') eq '0' ? oct($loc+0) : hex($loc); # HEX ONLY
	return -1 if $addr % 4;
	return $addr;
    }
    elsif ( $loc =~ m/^((.*)\s*:|l)\s*(\d+)$/i ) { # Lines
	my ($file,$line) = ($2,$3);
	($file) = ($lines[$reg[15]-8] =~ m/^(.+):/) if !$file;
	return -3 if !$file;
	for (my $i=0;$i<$#lines;$i+=4) {
	    return $i if $lines[$i] eq "$file:$line";
	}
	return -4;
    }
    return -2;
}

sub strloc {
    my ($pos) = @_;
    return sprintf("instruction %X, %s",$pos,$lines[$pos]) if $lines[$pos];
    return sprintf("instruction %X",$pos);
}

sub dlerr {
    my ($e) = @_;
    return "Must be on word boundary" if $e == -1;
    return "Unknown location format" if $e == -2;
    return "Filename detection failed" if $e == -3;
    return "Line not found" if $e == -4;
}

sub compose_psr {
    my $psr = $N.$Z.$C.$V.'0';		# NZCVQ			31-27
    $psr .= '0'x19;			# DNM (RAZ)		26-8
    $psr .= '110';			# IFT			7-5
    $psr .= '10000';			# Mode			4-0
    vprint "Loading from PSR: $psr\n";
    return bin2dec($psr);
}

sub decompose_psr {
    my $psr = dec2bin($_[0],32);
    vprint "Storing to   PSR: $psr\n";
    $N = armbits($psr,31,1);
    $Z = armbits($psr,30,1);
    $C = armbits($psr,29,1);
    $V = armbits($psr,28,1);
    if ( compose_psr() != bin2dec($psr) ) {
	print "Ignoring unsupported PSR flags\n";
    }
}

sub ror {
    no integer;
    my ($op2,$offset) = @_;
    my $carrymask = 1 << ($offset-1);
    my $fopco = ($op2 & $carrymask)?1:0;
    my $mask = ((1<<$offset)-1);
    my $lowbits = ($op2&$mask)<<(32-$offset);
    my $a = $op2 >> $offset;
    my $nop2 = $a+$lowbits;
    return wantarray?($nop2,$fopco):$nop2;
}
sub do_shift {
    my ($op2, $type, $offset, $offsetreg, $srcimmed) = @_;
    my $fopco = $C;
    if ( $type <= 0 && !$offset ) { return ($op2, $fopco) unless $offset }
    elsif ( $type == 0 ) { $op2 += $offset }
    elsif ( $type == -1 ) { # LSL
	my $carrymask = 1 << (32-$offset);
	$fopco = $op2 & $carrymask?1:0;
	$op2 <<= $offset;
    }
    elsif ( $type == 1 ) { # LSR
	no integer;
	$offset = 32 if $offset == 0 && !$offsetreg;
	my $carrymask = 1 << ($offset-1);
	$fopco = $op2 & $carrymask?1:0;
	$op2 >>= $offset;
    }
    elsif ( $type == 2 ) { # ASR
	no integer;
	$offset = 32 if $offset == 0 && !$offsetreg;
	my $carrymask = 1 << ($offset-1);
	$fopco = $op2 & $carrymask?1:0;
	my $highbit = $op2 & 0x80000000;
	$op2 >>= $offset;
	if ( $highbit ) {
	    my $highmask = $offset == 32 ? 0xFFFFFFFF : ((1<<$offset)-1)<<(32-$offset);
	    $op2 |= $highmask;
	}
    }
    elsif ( $type == 3 ) { # ROR and RRX
	if ( $offset > 0 || $offsetreg || $srcimmed ) {
	    ($op2,$fopco) = ror($op2,$offset);
	}
	else {
	    no integer;
	    $fopco = $op2&1;
	    $op2 = ($C<<31)|($op2>>1);
	}
    }
    return ($op2, $fopco);
}

# The MUL (multiply with 32 bit result) and MLA (multiply and accumulate)
# instructions are present in all architectures.  The M variant also adds 4
# multiply instrctions with long (64) bit results.

# With "S" specified, the N and Z bits are set.
sub mul {
    no integer;
    my ($rm, $rs, $ra, $s) = @_;
    $rm &= 0xffffffff;
    $rs &= 0xffffffff;
    my ($rmh, $rml) = (($rm>>16)&0xffff, $rm & 0xffff);
    my ($rsh, $rsl) = (($rs>>16)&0xffff, $rs & 0xffff);
    my $res = ((($rml*$rsh+$rmh*$rsl) % 0x10000 )<<16) + $rml*$rsl;
#   my $res = $rm * $rs;
    $res %= 2**32;
    $res += $ra & 0xffffffff if defined($ra);
    if ( $s ) {
	$N = ($res & 0x80000000) ? 1 : 0;
	$Z = $res ? 0 : 1;
    }
    return $res;
}

sub memset {
    my ($addr, $val, $bytes) = @_;
    for (my $i = 0; $i<$bytes; $i++) {
      setmem($addr+$i, $val, 1);
    }
}

# Convert numbers to needed signed/unsigned format when used. Specify width
# depending on source.

# Use when (1) using number and (2) Changing size. e.g. converting
# signed_12_bit_immediate to register/etc

sub convert_to_signed {
    no integer;
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


sub convert_to_unsigned {
    my ($bits, $size) = @_;
    $size = 32 unless $size;
    $size > 1 or die;
    my $max = (1<<$size);         # one more than max unsigned value
    $bits &= $max - 1;
    return $bits;
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
