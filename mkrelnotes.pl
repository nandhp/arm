#!/usr/bin/perl
#
# Create release notes for arm.pl in HTML
#
use Digest::MD5 qw/md5_hex/;

open OUT, ">releasenotes.html" or die "Error opening release notes: $!";
print OUT <<END;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML>
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=ISO-8859-1">
<TITLE>Release Notes</TITLE>
<STYLE TYPE="text/css">
<!--
.header {background:#99cccc;font-weight:bold}
.subheader {background:#99cccc;font-weight:bold}
.normal {background:#eeeeee;$globalcss}
.empty {background:#cccccc;$globalcss}
.added {background:#aaffaa;$globalcss}
.removed {background:#ffaaaa;$globalcss}
.changea {background:#eeee77;$globalcss}
.changeb {background:#ffff77;$globalcss}
.white {$globalcss}
.fixed {font-family:courier;font-size:smaller}
.wrap {color:gray}
//-->
</STYLE>
</HEAD>
<BODY>
END

my @toc = ();
my $version = 'Unknown';

open ARM, "arm.pl" or die "Opening arm.pl: $!";
print OUT "<H1>ARM Simulator Release Notes</H1>";
my %instructions = ();
my @inskinds = ();
while (<ARM>) {
    if ( m/\$VERSION\s*=\s*['"]?(\d+)['"]?\s*;/ ) {
	$version = $1;
    }
    elsif ( m/\%instructions\s*=\s*\(/ ) {
	my $kind = '';
	my $a=0;
	while (<ARM>) {
	    s/[\r\n]//g;
	    s/^\s+|\s+$//g;
	    if ( m/^# (.+)$/ ) {
		$kind = $1;
		push @inskinds,$kind;
	    }
	    elsif ( m/^(\w+)\s*=\>/ ) {
		push @{$instructions{$kind}}, $1;
	    }
	    elsif ( m/^\);/ ) { last } # I hate cperl mode so much / ) {}
	}
	last;
    }
}

push @toc, "Instruction Summary",'+',@inskinds,'-',"What's New",'+',"Changes","Diff",'-', "Known Issues","Related Links";
print OUT "<P>Version $version\n\n<H2>Contents</H2><P>\n";
my @i = ();
push @i, "1";
print OUT "<TABLE CELLSPACING=0 CELLPADDING=0 BORDER=0>\n";
foreach (@toc) {
    if ( $_ eq '+' ) { push(@i,pop(@i)-1, 1); next }
    elsif ( $_ eq '-' ) { pop(@i);push(@i,pop(@i)+1); next }
    my $i = pop @i;
    my $target = md5_hex($_);
    print OUT "<TR><TD VALIGN=top>".join('.',@i,$i).".&nbsp;</TD><TD VALIGN=top><A HREF=\"#$target\">$_</A></TD></TR>\n";
    $i++;
    push @i, $i;
}
print OUT "</TABLE>";

$i = 1;

# Produce Instructions List
my $section = shift(@toc);
my $anchor = md5_hex($section);

print OUT "<P><A NAME=$anchor><H2>".$section."</H2></A><P>\n";
shift(@toc);
foreach ( @inskinds ) {
    shift @toc;
    my $anchor = md5_hex($_);
    print OUT "<A NAME=$anchor><H3>$_</H3></A>\n<UL>\n";
    foreach ( @{$instructions{$_}} ) {
	print OUT "<LI>$_</LI>\n";
    }
    print OUT "</UL>\n";
}
shift(@toc);

# What's New
$section = shift(@toc);
$anchor = md5_hex($section);

print OUT "<P><A NAME=$anchor><H2>".$section."</H2></A><P>\n";
shift(@toc);

# Changes
$section = shift(@toc);
$anchor = md5_hex($section);

print OUT "<P><A NAME=$anchor><H3>".$section."</H3></A><P>\n";

print OUT "<P><UL>\n";
open CHANGELOG, "ChangeLog" or die "Can't open ChangeLog: $!\n";
while (<CHANGELOG>) { last if m/^($version|LATEST)\s*$/ }
while (<CHANGELOG>) { next if m/^\s*$/;last if m/^\w/;m/^\s+(-?)\s+(.+?)[\r\n]+$/; print OUT ($1?'<LI>':'')."$2\n" if $2 }
print OUT "</UL>\n";
close CHANGELOG;

# Diff
$section = shift(@toc);
$anchor = md5_hex($section);

print OUT "<P><A NAME=$anchor><H3>".$section."</H3></A><P>\n";
opendir(DIR, "rel");
my @out = readdir DIR;
@out=sort @out;
closedir(DIR);
while ( 1 ) {
    last if !scalar(@pop);
    next unless ($_ = pop(@out)) =~ /^(\d+)$/;
    next if $_ eq $version;
    print "Chosen $_\n";
    last;
}
m/^(\d+)$/;
if ( !$_ ) {
    print OUT "<P>Nothing to compare against.\n";
}
else {
    s/[\r\n]//g;
    open DIFF, 'diff -U 10 rel/'.$_.'/arm.pl arm.pl|htmldiff.pl|';
    while (<DIFF>) {
	last if m/\<body/i;
    }
    while (<DIFF>) {
	s/\<TD CLASS=header\>arm.pl\<\/TD\>/\<TD CLASS=header\>Version $version\<\/TD\>/;
	s/\<TD CLASS=header\>rel\/(\d+)\/arm.pl/\<TD CLASS=header\>Version $1/;
	print OUT $_;
	last if m/\<\/table\>/i;
    }
    <DIFF>;
    print OUT <DIFF>;
}

shift(@toc);
# Known issues
$section = shift(@toc);
$anchor = md5_hex($section);

print OUT "<P><A NAME=$anchor><H2>".$section."</H2></A><P>\n";
print OUT "<P>None.\n";

# Resources
$section = shift(@toc);
$anchor = md5_hex($section);

print OUT "<P><A NAME=$anchor><H2>".$section."</H2></A><P>\n";
print OUT <<END;
<UL>
<LI><A HREF="http://nand.homelinux.com:8888/~nand/blosxom/blosxom.cgi">ARM Status Blog</A></LI>
</UL>
END
print OUT "</BODY></HTML>";
