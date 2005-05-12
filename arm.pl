#!/usr/bin/perl
use strict;
use warnings;
use integer;
use Getopt::Long qw(:config gnu_getopt);
use Pod::Usage;

my $VERSION='20050512';# yyyymmdd

my $v = 0;
my $help = 0;
my $man = 0;
my $q = 0;
my $d = 0;
GetOptions('debug|d' => \$d, 'verbose|v' => \$v, 'quiet|q' => \$q, 'help|h|?' => \$help, 'man' => \$man, 'version' => \&show_version) or show_help();
show_help(1) if $help;
show_help(2) if $man;

if ( $d ) {
    print "Spawning debugger...\n";
    my @args = (
		$v?('-'.('v'x$v)):'',
		$q?'-q':'',
	       );
    system('perl','-d','arm.pl',
	   @args,
	   @ARGV);
    exit();
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

This switch is actually pretty cool. When you use it, arm.pl respawns
itself under perl(1)'s debugger so you can do neat tricks like

I<./add.s -vd>

and debug arm.pl while running add.s. Neat, eh?

=back

=head1 DESCRIPTION

B<arm.pl> will parse the given input file(s) as ARM assembler and
attempt to execute them.

=cut

sub show_help {
    $_[0]||=0;
    if ( $_[0] == 0 ) {
	pod2usage(-verbose => 0,-msg => " ");
    }
    elsif ( $_[0] == 1 ) {
	pod2usage(-verbose => 1,-msg => "arm.pl version $VERSION\n");
    }
    elsif ( $_[0] == 2 ) {
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

# '.text' => 2,# comma separated list of quoted strings and numeric constants; strings encoded as bytes, numbers encoded as bytes.
# '.data' => 2,# comma separated list of numeric constants, one 32-bit word each
#'.align' => 2,# numeric argument, advances PC so its value is 0 mod argument.
#  .text "foo",0,"bar",0177,0xff,10,13,0
#  .data 4,5,0xffffeeee, -1, 42
#  .align 8

my %instructions = (
		    # Unimplemented instructions
		    LDM => 1,
		    STM => 1,
		    BIC => 1,
		    ORR => 1,
		    AND => 1,
		    TEQ => 1,
		    TST => 1,
		    MSR => 1,
		    MRS => 1,
		    MVN => 1,
		    MLA => 1,
		    MUL => 1,
		    RSC => 1,
		    RSB => 1,
		    SBC => 1,

		    # Implemented instructions
		    B   => 1,
		    BL  => 1,
		    MOV => 1,
		    # Beta instructions
		    CMP => 1,
		    ADD => 1,
		    LDR => 1,
		    STR => 1,
		    # Alpha instructions
		    CMN => 1,
		    SUB => 1,
		    ADC => 1,
		    EOR => 1,

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
my %labels = ();
# A program is an array of arrays.
#
# Each array is an instruction. The first item is the instuction name
# -opcode if you insist- of the instruction. The executor takes each
# array, looks at the first element, and passes it to the appropriate
# code: The code for "BRANCH" say.
#
# Labels are stored seperately and are aray indexes.
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
my $lastlabel='';
while (my $line = <>) {
    $line =~ s/[\r\n]//g;
    vprint "$line \n";
    next if $line =~ /^\s*;/;
    next if $line =~ /^#!/;
    next if $line =~ /^\s*$/;

    # Check for a label
    if ( $line =~ s/^(\w+):(\s+|$)// ) {
	my ($label,$ws) = (lc $1,$2);
	$lastlabel=$label;
	vprint "Number: $insnum\t Label: $label\n";
	$labels{$label}=$insnum;
	next unless $ws;
    }

    $line =~ s/;.+$//; # FIXME
    $line =~ s/^\s*//;
    $line =~ s/\s*$//;

    if ( $line =~ /^DC([BDW])\s+(.+)$/i ) {
	# FIXME
	my $bdw = uc $1;
	my $vals = $2;
	vprint "Processing DC$1...\n";
	if ( $bdw eq 'D' ) {
	    print "WARN: Processing DCD as DCW\n";
	    $bdw = 'W';
	}
	if ( !$lastlabel ) { print STDERR "WARN: No label for DC\n" }
	if ( $vals =~ /,/ ) { print STDERR "WARN: More than one value unsupported at this time!\n" }
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

    # Parse instruction
    my ($ins,$cond,$extra,$params) = $line =~ /^($insmatch)($condmatch)?($xmatch)?(?:\s+(.+))?$/i or throw("Parse Error");
    $cond ||= "AL";
    ($ins,$cond,$extra) = (uc $ins,uc $cond,uc $extra); # Uppercase some
    vprint "Number: $insnum\nInstruction: $ins\nCondition: $cond\nExtra: $extra\n";
    $params ||= "";
    my @params = ();
    # FIXME: Flexible Operand 2
    while ( $params =~ /\s*([\-A-Z0-9#&]+\s*(,\s*($fopmatch).*)?|\[R\d+(,\s*($fopmatch)?\s*#-?\d+)?\]|=?\w+)\s*(,\s*|$)/gi ) {
	if ( $2 && ($2 !~ /^\[/ || $5) ) { throw("Rotational and Shifting FOPs are not supported") }
	push @params, $1;
	vprint "Param: $1\n";
    }
    my @instruction = ($ins,$cond,$extra);
    push @instruction, @params;
    push @program, \@instruction;
    $insnum++;
    vprint "\n";
}
push @program, 0;			# Last instruction should be 0 - See branch
# Run it
my ($N,$Z,$C,$V) = (0,0,0,0);
my $S = 0;
my $B = 0;

my @reg = ();
print "Begining execution on instruction 0\n";
$reg[15]=0; # PC
while ( $program[$reg[15]] ) {
    #my $pc = $reg[15]; # Convenience
    my $oldpc = $reg[15];
    last unless $program[$reg[15]];
    my @ins = @{$program[$reg[15]]};
    print("Executing $reg[15]: ".join(' ',@ins[0..2]).' '.join(', ',@ins[3..$#ins])."\n") if $v > -1;

    # Check conditional
    if ( $ins[1] eq 'AL' ) { }
    elsif ( $ins[1] eq 'NV' ) { $reg[15]++; next }
    elsif ( $ins[1] eq 'EQ' ) { vprint "EQ: Z=$Z\n";($reg[15]++,next) if !$Z } # Skip if NE
    elsif ( $ins[1] eq 'NE' ) { vprint "NE: Z=$Z\n";($reg[15]++,next) if $Z }
    elsif ( $ins[1] eq 'CS' ) { vprint "CS: C=$C\n";($reg[15]++,next) if !$C }
    elsif ( $ins[1] eq 'CC' ) { vprint "CC: C=$C\n";($reg[15]++,next) if $C }
    elsif ( $ins[1] eq 'MI' ) { vprint "MI: N=$N\n";($reg[15]++,next) if !$N }
    elsif ( $ins[1] eq 'PL' ) { vprint "PL: N=$N\n";($reg[15]++,next) if $N }
    elsif ( $ins[1] eq 'VS' ) { vprint "VS: V=$V\n";($reg[15]++,next) if !$V }
    elsif ( $ins[1] eq 'VC' ) { vprint "VC: V=$V\n";($reg[15]++,next) if $V }
    elsif ( $ins[1] eq 'GE' ) { vprint "GE: N=$N,V=$V,Z=$Z\n";
				($reg[15]++,next) if $V != $N }
    elsif ( $ins[1] eq 'LT' ) { vprint "LT: N=$N,V=$V,Z=$Z\n";
				($reg[15]++,next) if $V == $N }
    elsif ( $ins[1] eq 'GT' ) { vprint "GT: N=$N,V=$V,Z=$Z\n";
				($reg[15]++,next) if $V != $N || $Z }
    elsif ( $ins[1] eq 'LE' ) { vprint "LE: N=$N,V=$V,Z=$Z\n";
				($reg[15]++,next) if $V == $N && !$Z  }
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
		$reg[14]=$reg[15]+1;
		vprint "Link: Return to instruction $reg[14]\n";
	    }
	    $reg[15]=$target;
	}
	else { throw("Error parsing branch. No label $ins[3]") }
    }
    elsif ( $ins[0] eq 'MOV' ) { # MOV{cond}{S} Rd, <Operand2>
	throw("S flag unsupported due to unknown function") if $ins[2] eq 'S';
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = $ins[4];
	    vprint "Placing $ins[4] in R$reg\n";
	}
	else { throw("Non-register target for MOV $reg[15]") }
    }
    elsif ( $ins[0] eq 'ADD' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armadd($ins[4],$ins[5],0,$S);
	    vprint "Placing $ins[4]+$ins[5]=$reg[$reg] in R$reg\n";
	}
	else { throw("Non-register target for ADD $reg[15]") }
    }
    elsif ( $ins[0] eq 'ADC' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armadd($ins[4],$ins[5],$C?1:0,$S);
	    vprint "Placing $ins[4]+$ins[5]=$reg[$reg] in R$reg\n";
	}
	else { throw("Non-register target for ADC $reg[15]") }
    }
    elsif ( $ins[0] eq 'SUB' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armsub($ins[4],$ins[5],1,$S);
	    vprint "Placing $ins[4]-$ins[5]=$reg[$reg] in R$reg\n";
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
	}
	else { throw("Non-register target for LDR $reg[15]") }
    }
    elsif ( $ins[0] eq 'EOR' ) {
	@ins[4..$#ins] = translate(@ins[4..$#ins]); # Do not translate 3
	if ( defined(my $reg = isreg($ins[3])) ) {
	    $reg[$reg] = armxor($ins[4],$ins[5],$S);
	    vprint "Placing $ins[4]^$ins[5]=$reg[$reg] in R$reg\n";
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
	throw("Program died on instruction $reg[15]");
    }
    elsif ( $ins[0] eq 'END' ) { last } # Nonstandard instruction
    elsif ( $ins[0] eq 'OUT' ) { # Nonstandard instruction
	my @oldins = @ins;
	@ins[3..$#ins] = translate(@ins[3..$#ins]);
	for ( my $i=3;$i<= $#ins;$i++ ) {
	    if ( $S ) {
		printf "$oldins[$i] = %#8x\n",$ins[$i];
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
	throw("Undefined instruction at $reg[15]");
    }
    $reg[15]++ unless $reg[15] != $oldpc; # If it's different don't bump it
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
    print "TODO: R15 only contains PC. See http://www.heyrick.co.uk/assembler/psr.html\n" if $pos eq 'PC' or $pos eq 'R15';
    return 15 if $pos eq 'PC';
    return 14 if $pos eq 'LR';
    if ( $pos =~ /^R(\d+)$/ ) {
	return undef unless $1 >= 0 && $1<=15;
	return $1;#wantarray ? [1,$reg[$1]] : 1;
    }
    return undef;
}
sub translate {
    foreach ( @_ ) {
	my $offset = 0;
	$_ =~ s/^\[(.+)\]$/$1/; # Address
	# =Label => [PC,#offset]
	if ( $_ =~ s/,\s*(.+)$// ) {
	    my $fop = $1;
	    vprint "FOP: $1\n";
	    if ( $fop =~ /^#(-?\d+)$/ ) { # Numbers
		$offset = $1;
	    }
	    else { throw("Bad FOP - got through the parser but not the translator? $_") }
	}
	print "TODO: R15 only contains PC. See http://www.heyrick.co.uk/assembler/psr.html\n" if $_ eq 'PC' or $_ eq 'R15';
	if ( uc $_ eq 'PC' ) { $_ = $reg[15] }
	elsif ( $_ =~ /^R(\d+)$/i ) { # Do this manually so we can Throw.
	    throw("$_ is not in range 0-15") unless $1 >= 0 && $1<=15;
	    $reg[$1]||=0;
	    vprint "Translating $_ to $reg[$1]\n";
	    $_ = $reg[$1] + $offset;
	    vprint "   (plus FOP Offset $offset equals $_)\n" if $offset;
	}
	elsif ( $_ =~ /^#(-?\d+)$/ ) { # Numbers
	    $_ = $1+0;
	}
	elsif ( $_ =~ /^(?:&|#0x)(-?[\dA-F]+)$/i ) { # Hex Numbers (?)
	    $_ = hex($1);
	}
	elsif ( $_ =~ /^(=?)(\w+)$/i ) {
	    #if ( $1 ) { vprint "NOT TRANSLATING =$2\n";return }
	    if ( $1 ) {
		$_ = exists($labels{lc $2}) && $labels{lc $2}=~ /^(\d+)\|(\d+)$/?$1:$_;
	    }
	    else {
		my $ol = $_;
		$_ = exists($labels{lc $2}) && $labels{lc $2}=~ /^(\d+)\|(\d+)$/?getmem($labels{lc $2}[0],$labels{lc $2}[1]):$_;
		vprint "Translating $ol to $_\n";
	    }
	}
	if ( $_ =~ /^\d+$/ ) { $_+=0 }
	# Let someone else deal with it.
    }
    return @_;
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
    if ( $s ) {
	vprint "Setting S flags\n";
	#my $ci=(($a & 0x7FFFFFFF)+($b & 0x7FFFFFFF)) & 0x80000000;
	my $hba = ($a & 0x80000000)?1:0;
	my $hbb = ($b & 0x80000000)?1:0;

	$N = $result & 0x80000000 ? 1:0;
	$Z = $result == 0         ? 1:0;
	$C = 0; # Use rotational or shifting FOP Carry Out.
	#$V = 0;
	vprint "CI: N/A\tN: $N\tZ: $Z\tC: $C\tV: N/A\n";
    }
    return $result;
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

