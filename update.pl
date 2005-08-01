#!/usr/bin/perl
#
# ARM Simulator Update
#

use Tk;
use Tk::ProgressBar;
use LWP::UserAgent;
use HTTP::Request;
use IO::Socket::INET;
use URI;
use Digest::MD5;
use Archive::Tar;
use Cwd;

$Archive::Tar::CHOWN = 0;
$| = 1;

my $myversion = 1;			# Version of update.pl

my $win32 = 0;
my $ShellExecute;
if ( $^O eq 'MSWin32' ) {
    $win32 = 1;
    eval 'use Win32::API';
    $ShellExecute = Win32::API->new("shell32","ShellExecute", "NPPPPI", "N");
}

my $imgdata = '';
while ( <DATA> ) { $imgdata .= $_ }

my $title = 'ARM Simulator Update';
my $update_url = 'http://nand.homelinux.com:8888/~nand/blosxom/update/au_check.cgi?updater='.$myversion;

my $wiztitle = '';
my $top = new Tk::MainWindow(-title => $title);

my $topframe = $top->Frame(-background => 'white',-height=>60,-width => 500);
my $icon = $top->Photo(-data => $imgdata);
$topframe->pack();
$topframe->Label(-text => " ", -background => 'white')->pack(-side => 'left');
$topframe->Label(-textvariable => \$wiztitle, -background => 'white', -anchor => 'w', -justify => 'left', -width => 60, -height=>4)->pack(-side => 'left');
$topframe->Label(-text => " ", -background => 'white')->pack(-side => 'right');
$topframe->Label(-image => $icon, -width => 48, -height=>48, -background => 'white')->pack(-side => 'right');

my $omainframe = $top->Frame(-border => 2,-relief => 'groove');
$omainframe->pack(-fill => 'both',-expand => 'both');
my $mainframe = $omainframe->Frame();
$mainframe->pack(-padx => 12, -pady => 12,-fill => 'both',-expand => 'both');
my @pagewidgets =();

my $butframe = $top->Frame();
$butframe->pack(-fill => 'x', -padx => 7, -pady => 7);
my $cancel = $butframe->Button(-text => 'Cancel', -width => 9,
			       -command => \&WizCancel);
$cancel->pack(-side => 'right');
my $bfl = $butframe->Label(-text => ' ');$bfl->pack(-side => 'right');
my $next = $butframe->Button(-text => 'Next >', -width => 9,
			     -command => \&WizNext);
$next->pack(-side => 'right');
my $back = $butframe->Button(-text => '< Back', -width => 9);
$back->pack(-side => 'right');

$top->update();
my $bg = $top->cget(-background);
my $g = $top->geometry();
$g =~ m/^(\d+)/;
$top->geometry($1.'x350');
$top->resizable(0,0);

my $page = 0;

WizardPage();

my $version;

# Read version in from arm.pl file
open ARM, "arm.pl";
while (<ARM>) {
    if ( m/\$VERSION\s*=\s*['"]?(\d*\.?\d+)['"]?\s*;/ ) {
	$version = $1;
	last;
    }
}
close ARM;

sleep 1;
if ( $version || 1) {
    $pagewidgets[0]->value(1);
    $update_url .= '&version='.$version;
}
else {
    $top->messageBox(-icon => 'error', -type => 'OK', -title => $title, -message => "New installations are not currently supported");
    exit(0);
}
$top->update();
my @current = split("\n",get($update_url));
if ( scalar (@current) ) {
    $pagewidgets[0]->value(2);
}
else {
    $top->messageBox(-icon => 'error', -type => 'OK', -title => $title, -message => "The update server did not respond");
    exit(0);
}

$top->update();

if ( $current[0] > $version ) {
    sleep 1;
    $page = 1;
    WizardPage();
}
else {
    $top->messageBox(-icon => 'info', -type => 'OK', -title => $title, -message => "No updates are available");
    exit(0);
}

MainLoop();

unlink "temp/update.tar.gz";
rmdir 'temp';

sub WizardPage {
    foreach ( @pagewidgets ) {
	$_->destroy();
    }
    @pagewidgets = ();
    $next->configure(-state => 'normal');
    $back->configure(-state => 'normal');
    $cancel->configure(-state => 'normal');
    my $w;
    if ( $page == 0 ) {
	$wiztitle = "Please wait\n        Starting the ARM Simulator Update Wizard.";
	$w = $mainframe->ProgressBar(-border => 2, -relief => 'sunken', -troughcolor => $bg, -colors => [0,'navy'],-from => 0, -to => 2, -blocks => 1);
	$w->pack(-expand => 1, -fill => 'x');
	push @pagewidgets, $w;
	$next->configure(-state => 'disabled');
	$back->configure(-state => 'disabled');
    }
    elsif ( $page == 1 ) {
	$back->configure(-state => 'disabled');

	$w = $mainframe->Label(-text => ($version?"Current version: $version\n":"")."Latest version: $current[0]\n", -justify => 'left', -anchor => 'w');
	$w->pack( -fill => 'x');
	push @pagewidgets, $w;
	if ( $version ) {
	    $wiztitle = "Select updates\n        Updates are available to be installed.";
	    my $f = $mainframe->Frame();
	    push @pagewidgets, $f;
	    $f->pack( -fill => 'x');
	    $w = $f->Label(-text => "Read more about this update: ");
	    $w->pack(-side => 'left');
	    $w = $f->Button(-text => " Go ", -command => \&GoASB);
	    $w->pack(-side => 'right');
	    $w = $mainframe->Label(-text => "Click Next to upgrade the ARM simulator installation in this directory.", -justify => 'left', -anchor => 'sw');
	}
	else {
	    $wiztitle = "Confirm Installation\n        A new copy of the ARM Simulator will be installed here.";
	    my $dir = getcwd();
	    my $rl = $mainframe->Label(-text => "The ARM Simulator is not currently installed in this directory:\n\n        $dir", -justify => 'left', -anchor => 'w');
	    $rl->pack( -fill => 'x');
	    #my $f = $mainframe->Frame();
	    #$f->pack( -fill => 'x');
	    #$w = $f->Label(-text => "Directory: ");
	    #$w->pack(-side => 'left');
	    #$w = $f->Entry(-text => $dir); $w->pack(-side => 'left', -expand => 'x', -fill => 'x');
	    #push @pagewidgets, $w;
	    #$w = $f->Button(-text => " Browse ", -command => \&GoBrowse);
	    #$w->pack(-side => 'right');
	    #push @pagewidgets, $f;
	    $w = $mainframe->Label(-text => "Click Next to install the ARM simulator in this directory.", -justify => 'left', -anchor => 'sw');
	    push @pagewidgets, $rl;
	}
	$w->pack( -fill => 'x', -side => 'bottom');
	push @pagewidgets, $w;
    }
    elsif ( $page == 2 ) {
	$wiztitle = "Please wait\n        The updates you selected are being downloaded and installed.";
	my $f = $mainframe->Frame();$f->pack(-expand => 1, -fill => 'x');
	my $p = $f->ProgressBar(-border => 2, -relief => 'sunken', -troughcolor => $bg, -colors => [0,'navy'],-from => 0, -to => 1, -blocks => 1);
	push @pagewidgets, $p;
	$w = $f->Label(-text => "Please wait...", -justify => 'left', -anchor => 'w');
	$w->pack(-fill => 'x');
	push @pagewidgets, $w;
	$p->pack(-fill => 'x');
	$next->configure(-state => 'disabled');
	$back->configure(-state => 'disabled');
    }
    $top->update();
}

sub WizCancel {
    $top->destroy();
    undef $top;
}

my $downsock;

sub WizNext {
    if ( $page == 1 ) {
	#if ( !$version ) {
	#    my $d = $pagewidgets[1]->get();
	#    mkdir $d if !-d $d;
	#    if ( !chdir $d ) {
	#	$top->messageBox(-icon => 'error', -type => 'OK', -title => $title, -message => "Could not create directory.");
	#	return;
	#    }
	#}
	$page=2;
	WizardPage();
	$top->update();

	my $uri = URI->new($current[2]);
	$downsock = IO::Socket::INET->new($uri->host_port()) or ($top->messageBox(-icon => 'error', -type => 'OK', -title => $title, -message => "Could not download update (error 3)."),exit(0));
	$top->update();

	binmode $downsock;
	my $p = $uri->path()||'/';
	print $downsock "GET $p HTTP/1.0\r\n";
	print $downsock "User-Agent: update.pl/$myversion\r\n";
	print $downsock "Host: ".$uri->host()."\r\n";
	print $downsock "\r\n";

	<$downsock> =~ /^HTTP\/\d+\.\d+ (\d+)/;
	if ( $1 != 200 ) {
	    $top->messageBox(-icon => 'error', -type => 'OK', -title => $title, -message => "Could not download update (error 2).");
	    exit(0)
	}
	$top->update();
	my $length = 0;
	while (<$downsock>) {
	    s/[\r\n]//g;
	    if ( m/^Content-Length: (\d+)$/i ) {
		$length = $1;
	    }
	    elsif ( !$_ ) {
		last;
	    }
	}
	my $label = $pagewidgets[1];
	my $pb;
	$pb = $pagewidgets[0] if $length;
	$pb->configure(-to => $length) if $pb;
	$top->update();

	my $hl = h($length);
	# Prepare output
	mkdir 'temp';
	open OUT, ">temp/update.tar.gz";
	binmode(OUT);

	my $data;
	my $count = 0;
	my $inc = 256;
	my $rc = 0;
	while ( $rc = read($downsock,$data,$inc) ) {
	    print OUT $data;
	    $count += $inc;
	    $pb->value($count);
	    $label->configure(-text => $pb?('Downloading: '.h($count).' of '.$hl.'...'):('Downloading: '.h($count).' of unknown...')) unless $count/$inc % 5;
	    $top->update();
	    return unless $top;
	}
	close OUT;
	$pb->value(0) if $pb;
	$label->configure(-text => 'Verifying download...');
	$top->update();

	my $tar = Archive::Tar->new('temp/update.tar.gz',1);
	my @files = $tar->list_files();
	$pb->configure(-to => @files+1+2);
	$top->update();
	$count = 0;

	open IN, "temp/update.tar.gz";
	binmode(IN);
	my $md5 = Digest::MD5->new();
	$md5->addfile(IN);
	my $cksum = lc $md5->hexdigest;
	print "Checksumming...\n\n";
	print 'Ours:  ',$cksum,"\n";
	print 'Valid: ',$current[3],"\n";

	if ( $cksum != $current[3] ) {
	    $top->messageBox(-icon => 'error', -type => 'OK', -title => $title, -message => "Checksum does not match");
	    exit(0)
	}
	$count=1;
	$pb->value($count) if $pb;
	$cancel->configure(-state => 'disabled');
	$top->update();
	foreach ( @files ) {
	    my $fn = $_;
	    $fn =~ s/^(\.|\d+)\///;
	    my $pd = $1;
	    $label->configure(-text => 'Extracting '.$fn.'...');
	    $count++;
	    $pb->value($count) if $pb;
	    $top->update();
	    $tar->extract($_);
	}
	$label->configure(-text => 'Finishing up...');
	$pb->value($count+1) if $pb;
	$top->update();
	if ( -f "postinstall.pl" ) {
	    do "postinstall.pl";
	    unlink "postinstall.pl";
	}
	$label->configure(-text => 'Deleting temporary files...');
	$pb->value($count+2) if $pb;
	$top->update();
	undef $tar;
	unlink "temp/update.tar.gz";
	rmdir 'temp';
	$cancel->destroy();
	$back->destroy();
	$bfl->destroy();
	$next->configure(-text => "Finish", -state => 'normal');
	$label->configure(-text => 'Update complete.');
    }
    elsif ( $page == 2 ) {
	$top->destroy();
    }
}
sub GoBrowse {
    my $ent = $pagewidgets[1];
    my $dir = $top->chooseDirectory;
    if (defined $dir and $dir ne '') {
	$ent->delete(0, 'end');
	$ent->insert(0, $dir);
	$ent->xview('end');
    }
}

sub GoASB {
    if ( $win32 && $ShellExecute ) {
	$ShellExecute->Call("","",$current[1],"","",SW_SHOWNORMAL);
    }
    elsif ( $win32 ) {
	system 'start', $current[1];
    }
    elsif ( -x '/etc/alternatives/x-www-browser' ) {
	system '/etc/alternatives/x-www-browser "'.$current[1].'"&';
    }
    elsif ( -x `which sensible-browser` ) {
	system 'sensible-browser "'.$current[1].'"&';
    }
    elsif ( -x `which firefox` ) {
	system 'firefox "'.$current[1].'"&';
    }
    elsif ( -x `which mozilla` ) {
	system 'mozilla "'.$current[1].'"&';
    }
    elsif ( -x `which netscape` ) {
	system 'netscape "'.$current[1].'"&';
    }
}

sub h {
    my ($bytes) = @_;
    $suffix = ' bytes';
    if ( $bytes >= 1024 ) { $bytes /= 1024; $suffix = 'Kb' }
    if ( $bytes >= 1024 ) { $bytes /= 1024; $suffix = 'Mb' }
    if ( $bytes >= 1024 ) { $bytes /= 1024; $suffix = 'Gb' }
    return (sprintf("%.1f",$bytes)*10/10).$suffix;
}

sub get {
    my ($url) = @_;

    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new(GET => $url);
    $request->push_header(Pragma => "no-cache");
    $request->push_header("Cache-Control" => "no-cache");
    $request->push_header("User-Agent" => "update.pl/$myversion");
    $ua->env_proxy();
    my $response = $ua->request($request);
    if ($response->is_success) {
	return $response->content;
    }
    else {
	return '';
    }
}

exit;

# Download Pixmap
__DATA__
/* XPM */
static char * updatewizard_xpm[] = {
"48 48 480 2",
"  	c None",
". 	c #FFFFFF",
"+ 	c #B0B0B0",
"@ 	c #606060",
"# 	c #303030",
"$ 	c #010A01",
"% 	c #051F05",
"& 	c #101010",
"* 	c #505050",
"= 	c #A0A0A0",
"- 	c #202020",
"; 	c #0D3C0E",
"> 	c #176F19",
", 	c #1FA522",
"' 	c #1DA720",
") 	c #1BAA1E",
"! 	c #19AC1B",
"~ 	c #138E14",
"{ 	c #084208",
"] 	c #D0D0D0",
"^ 	c #F0F0F0",
"/ 	c #404040",
"( 	c #0C300D",
"_ 	c #208923",
": 	c #49BD4B",
"< 	c #5ACD5B",
"[ 	c #68DA68",
"} 	c #62DA63",
"| 	c #5BD95C",
"1 	c #45CD46",
"2 	c #29BC2A",
"3 	c #15B217",
"4 	c #0F9211",
"5 	c #032203",
"6 	c #222822",
"7 	c #19601B",
"8 	c #59C55B",
"9 	c #88EB89",
"0 	c #92F192",
"a 	c #91F191",
"b 	c #8CEF8C",
"c 	c #84ED84",
"d 	c #7AEB7A",
"e 	c #6FE86F",
"f 	c #62E562",
"g 	c #46D647",
"h 	c #1ABA1B",
"i 	c #10AB11",
"j 	c #022203",
"k 	c #278129",
"l 	c #78DF79",
"m 	c #94F194",
"n 	c #9CF49C",
"o 	c #A1F5A1",
"p 	c #9FF49F",
"q 	c #99F399",
"r 	c #8FF08F",
"s 	c #77EA77",
"t 	c #6AE76A",
"u 	c #5CE45C",
"v 	c #4ADD4A",
"w 	c #1ABF1B",
"x 	c #0DA30E",
"y 	c #101B10",
"z 	c #E0E0E0",
"A 	c #1C5B1D",
"B 	c #73DE74",
"C 	c #9EF49E",
"D 	c #A9F7A9",
"E 	c #B0F8B0",
"F 	c #AEF8AE",
"G 	c #A5F6A5",
"H 	c #8BEF8B",
"I 	c #7DEC7D",
"J 	c #60E560",
"K 	c #51E151",
"L 	c #40DB40",
"M 	c #13BF14",
"N 	c #088209",
"O 	c #909090",
"P 	c #C0C0C0",
"Q 	c #09260A",
"R 	c #65D766",
"S 	c #87EE87",
"T 	c #96F296",
"U 	c #A4F6A4",
"V 	c #B3F9B3",
"W 	c #BDFCBD",
"X 	c #BAFBBA",
"Y 	c #ADF8AD",
"Z 	c #81ED81",
"` 	c #72E972",
" .	c #63E563",
"..	c #53E153",
"+.	c #45DE45",
"@.	c #2FD52F",
"#.	c #0BBE0C",
"$.	c #022F02",
"%.	c #001900",
"&.	c #007300",
"*.	c #000000",
"=.	c #3B963C",
"-.	c #79EB79",
";.	c #7FDF7F",
">.	c #548854",
",.	c #334C33",
"'.	c #2D3E2D",
").	c #6D8E6D",
"!.	c #B0ECB0",
"~.	c #90F090",
"{.	c #54E254",
"].	c #36DA36",
"^.	c #17C817",
"/.	c #079C08",
"(.	c #003E01",
"_.	c #009800",
":.	c #00CD00",
"<.	c #00A600",
"[.	c #0A220A",
"}.	c #5DD35D",
"|.	c #336633",
"1.	c #808080",
"2.	c #212E21",
"3.	c #9DE79D",
"4.	c #9AF39A",
"5.	c #8CF08C",
"6.	c #7EEC7E",
"7.	c #70E870",
"8.	c #61E561",
"9.	c #52E152",
"0.	c #43DD43",
"a.	c #34DA34",
"b.	c #23D323",
"c.	c #08C209",
"d.	c #047B04",
"e.	c #03AE04",
"f.	c #02C903",
"g.	c #00CC00",
"h.	c #235F23",
"i.	c #122B12",
"j.	c #1D2D1D",
"k.	c #86EE86",
"l.	c #6BE76B",
"m.	c #5DE45D",
"n.	c #4EE04E",
"o.	c #40DD40",
"p.	c #32D932",
"q.	c #23D523",
"r.	c #0DC80D",
"s.	c #05C605",
"t.	c #01CB01",
"u.	c #004000",
"v.	c #549454",
"w.	c #71E971",
"x.	c #64E664",
"y.	c #57E257",
"z.	c #49DF49",
"A.	c #3CDB3C",
"B.	c #2DD82D",
"C.	c #1FD41F",
"D.	c #10D010",
"E.	c #03CD03",
"F.	c #707070",
"G.	c #003300",
"H.	c #000C00",
"I.	c #000A00",
"J.	c #0F1D0F",
"K.	c #67E667",
"L.	c #4FE04F",
"M.	c #35DA35",
"N.	c #28D728",
"O.	c #1AD31A",
"P.	c #0CD00C",
"Q.	c #01CD01",
"R.	c #008C00",
"S.	c #868686",
"T.	c #E6E6E6",
"U.	c #E1E1E1",
"V.	c #DDDDDD",
"W.	c #D9D9D9",
"X.	c #D5D5D5",
"Y.	c #D1D1D1",
"Z.	c #CDCDCD",
"`.	c #C9C9C9",
" +	c #C5C5C5",
".+	c #C2C2C2",
"++	c #C4C4C4",
"@+	c #B6B6B6",
"#+	c #6D6D6D",
"$+	c #181818",
"%+	c #275627",
"&+	c #5FD75F",
"*+	c #47DE47",
"=+	c #3BDB3B",
"-+	c #2ED82E",
";+	c #21D521",
">+	c #13D213",
",+	c #06CE06",
"'+	c #005900",
")+	c #F9F9F9",
"!+	c #EEEEEE",
"~+	c #E5E5E5",
"{+	c #DCDCDC",
"]+	c #9E9E9E",
"^+	c #494949",
"/+	c #0C1C0C",
"(+	c #327332",
"_+	c #5ED75E",
":+	c #59E359",
"<+	c #3DDC3D",
"[+	c #31D931",
"}+	c #26D626",
"|+	c #19D319",
"1+	c #FAFAFA",
"2+	c #F7F7F7",
"3+	c #ECECEC",
"4+	c #E4E4E4",
"5+	c #D8D8D8",
"6+	c #D4D4D4",
"7+	c #CCCCCC",
"8+	c #C8C8C8",
"9+	c #6E6E6E",
"0+	c #0F2A0F",
"a+	c #3A9B3A",
"b+	c #56E256",
"c+	c #4CE04C",
"d+	c #44DE44",
"e+	c #27D727",
"f+	c #1CD41C",
"g+	c #10D110",
"h+	c #04CE04",
"i+	c #00B300",
"j+	c #F3F3F3",
"k+	c #FBFBFB",
"l+	c #F5F5F5",
"m+	c #E9E9E9",
"n+	c #E3E3E3",
"o+	c #DFDFDF",
"p+	c #DBDBDB",
"q+	c #D7D7D7",
"r+	c #D3D3D3",
"s+	c #CFCFCF",
"t+	c #CBCBCB",
"u+	c #C7C7C7",
"v+	c #C3C3C3",
"w+	c #878787",
"x+	c #091C09",
"y+	c #2F8C2F",
"z+	c #4ADF4A",
"A+	c #44DD44",
"B+	c #3EDC3E",
"C+	c #37DA37",
"D+	c #2FD92F",
"E+	c #12D112",
"F+	c #07CE07",
"G+	c #008000",
"H+	c #EBEBEB",
"I+	c #E7E7E7",
"J+	c #E2E2E2",
"K+	c #DEDEDE",
"L+	c #DADADA",
"M+	c #D6D6D6",
"N+	c #D2D2D2",
"O+	c #CECECE",
"P+	c #CACACA",
"Q+	c #C6C6C6",
"R+	c #ACACAC",
"S+	c #103710",
"T+	c #2DA42D",
"U+	c #39DB39",
"V+	c #30D930",
"W+	c #2AD72A",
"X+	c #11D111",
"Y+	c #07CF07",
"Z+	c #EDEDED",
"`+	c #737373",
" @	c #A9A9A9",
".@	c #A1A1A1",
"+@	c #363636",
"@@	c #115111",
"#@	c #22BC22",
"$@	c #22D522",
"%@	c #16D216",
"&@	c #0ED00E",
"*@	c #05CE05",
"=@	c #101C10",
"-@	c #EFEFEF",
";@	c #F8F8F8",
">@	c #9C9C9C",
",@	c #092A09",
"'@	c #4A4A4A",
")@	c #EAEAEA",
"!@	c #E8E8E8",
"~@	c #929292",
"{@	c #1C1C1C",
"]@	c #0B690B",
"^@	c #0EC30E",
"/@	c #08CF08",
"(@	c #02CD02",
"_@	c #009900",
":@	c #373737",
"<@	c #F1F1F1",
"[@	c #4E4E4E",
"}@	c #207D23",
"|@	c #27C029",
"1@	c #1A931A",
"2@	c #041A04",
"3@	c #676767",
"4@	c #757575",
"5@	c #0E1A0E",
"6@	c #282828",
"7@	c #111811",
"8@	c #279A2B",
"9@	c #37D338",
"0@	c #146B14",
"a@	c #0F1A0F",
"b@	c #7A7A7A",
"c@	c #565656",
"d@	c #002600",
"e@	c #A6A6A6",
"f@	c #0E3A10",
"g@	c #2EA831",
"h@	c #3CDC3C",
"i@	c #25C925",
"j@	c #0D5D0D",
"k@	c #1B1B1B",
"l@	c #979797",
"m@	c #393939",
"n@	c #00C000",
"o@	c #2B2B2B",
"p@	c #959595",
"q@	c #5E5E5E",
"r@	c #18611A",
"s@	c #3FBC41",
"t@	c #5BE35B",
"u@	c #4BDF4B",
"v@	c #16B916",
"w@	c #043404",
"x@	c #B5B5B5",
"y@	c #AFAFAF",
"z@	c #1D1D1D",
"A@	c #004C00",
"B@	c #636363",
"C@	c #BCBCBC",
"D@	c #208A23",
"E@	c #5ED65E",
"F@	c #6CE86C",
"G@	c #64E564",
"H@	c #4DE04D",
"I@	c #40DC40",
"J@	c #13D113",
"K@	c #039A03",
"L@	c #545454",
"M@	c #949494",
"N@	c #0E1B0E",
"O@	c #006600",
"P@	c #A7A7A7",
"Q@	c #313131",
"R@	c #061D07",
"S@	c #2AA42D",
"T@	c #83ED83",
"U@	c #7CEC7C",
"V@	c #66E666",
"W@	c #2BD72B",
"X@	c #0ACF0A",
"Y@	c #0E270E",
"Z@	c #727272",
"`@	c #777777",
" #	c #585858",
".#	c #3D3D3D",
"+#	c #0F4610",
"@#	c #47BB49",
"##	c #94F294",
"$#	c #7FEC7F",
"%#	c #42DD42",
"&#	c #20D520",
"*#	c #0FD00F",
"=#	c #1C291C",
"-#	c #A8C3AE",
";#	c #7FAB89",
">#	c #80AC8A",
",#	c #81AE8B",
"'#	c #E3E8E4",
")#	c #242424",
"!#	c #187A1A",
"~#	c #76D877",
"{#	c #A4F5A4",
"]#	c #8AEF8A",
"^#	c #25D625",
"/#	c #56A458",
"(#	c #7CC771",
"_#	c #69B863",
":#	c #84B58D",
"<#	c #0F180F",
"[#	c #1EA621",
"}#	c #A7F0A7",
"|#	c #B1F9B1",
"1#	c #A2F5A2",
"2#	c #80EC80",
"3#	c #6EE86E",
"4#	c #27D627",
"5#	c #77B080",
"6#	c #409C49",
"7#	c #34973D",
"8#	c #359641",
"9#	c #AFD1B5",
"0#	c #093409",
"a#	c #3AB83C",
"b#	c #C1FDC1",
"c#	c #B5FAB5",
"d#	c #93F193",
"e#	c #3ADB3A",
"f#	c #28D628",
"g#	c #383838",
"h#	c #9A9A9A",
"i#	c #0F6010",
"j#	c #5BCC5C",
"k#	c #B2F9B2",
"l#	c #ACF7AC",
"m#	c #8EF08E",
"n#	c #38DB38",
"o#	c #15D215",
"p#	c #04B404",
"q#	c #0D190D",
"r#	c #5D5D5D",
"s#	c #BABABA",
"t#	c #7F7F7F",
"u#	c #169717",
"v#	c #7CE27D",
"w#	c #A0F5A0",
"x#	c #9DF49D",
"y#	c #02B402",
"z#	c #0A0A0A",
"A#	c #021603",
"B#	c #1DB31F",
"C#	c #84EE84",
"D#	c #6DE86D",
"E#	c #5EE45E",
"F#	c #3FDC3F",
"G#	c #1ED41E",
"H#	c #0DD00D",
"I#	c #094D0A",
"J#	c #33C334",
"K#	c #7BEB7B",
"L#	c #5CDB5D",
"M#	c #33C634",
"N#	c #44D144",
"O#	c #17D317",
"P#	c #202C20",
"Q#	c #0D7C0E",
"R#	c #3CCD3D",
"S#	c #45D246",
"T#	c #1EBC1F",
"U#	c #10AA12",
"V#	c #0E940F",
"W#	c #1ABD1B",
"X#	c #2CD82C",
"Y#	c #11B712",
"Z#	c #0EA010",
"`#	c #064406",
" $	c #011702",
".$	c #0EBA0F",
"+$	c #2FD12F",
"@$	c #032E04",
"#$	c #09740A",
"$$	c #077608",
"%$	c #11C112",
"&$	c #2AD62A",
"*$	c #09B40A",
"=$	c #11C811",
"-$	c #08CE08",
";$	c #023C02",
">$	c #07C307",
",$	c #05CA05",
"'$	c #024A02",
")$	c #04C704",
"!$	c #02CA02",
"~$	c #303C30",
"{$	c #014B01",
"]$	c #01CA01",
". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . . . . . . + @ # $ % & * = . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . . . . = - ; > , ' ) ! ~ { - ] . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . . ^ / ( _ : < [ } | 1 2 3 4 5 = . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . ] 6 7 8 9 0 a b c d e f g h i j + . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . ^ # k l m n o p q r c s t u v w x y z . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . * A B a C D E F G q H I e J K L M N / . . . . z O = . . . . ",
". . . . . . . . . . . . . . . . . P Q R S T U V W X Y C r Z `  ...+.@.#.$.P . P @ %.&.*.. . . . ",
". . . . . . . . . . . . . . . . . / =.-.;.>.,.'.).!.F p ~.Z `  .{.+.].^./.# - (._.:.<./ . . . . ",
". . . . . . . . . . . . . . . . z [.}.|.- O P P 1.2.3.4.5.6.7.8.9.0.a.b.c.d.e.f.g.:.&.O . . . . ",
". . . . . . . . . . . . . . . . O h.i.1.. . . . . = j.0 k.-.l.m.n.o.p.q.r.s.t.g.:.:.u.] . . . . ",
". . . . . . . . . . . . . . . . P / = . . . . . . . @ v.I w.x.y.z.A.B.C.D.E.:.:.:.:.- . . . . . ",
". . . . . . F./ / / / / / / / / / / & u.G.G.H.G.*.H.I.J.` K.u L.0.M.N.O.P.Q.:.:.:.R.@ . . . . . ",
". . . . . O S.T.U.V.W.X.Y.Z.`. +.+.+.+++.+.+.+.+@+#+$+%+&+u 9.*+=+-+;+>+,+:.:.:.:.'+= . . . . . ",
". . . . . / )+!+~+U.{+W.X.Y.Z.`. +.+.+++++.+]+^+/+(+_+J :+K *+<+[+}+|+P.Q.:.:.:.:.%.^ . . . . . ",
". . . . . / 1+2+3+4+z {+5+6+] 7+8+++++++++9+0+a+:+:+b+9.c+d+A.p.e+f+g+h+:.:.:.:.i+# . . . . . . ",
". . . . . / j+k+l+m+n+o+p+q+r+s+t+u+v+.+.+w+x+y+z+z+*+A+B+C+D+}+f+E+F+:.:.:.:.:.G+1.. . . . . . ",
". . . . . / H+l+k+j+I+J+K+L+M+N+O+P+Q+.+.+.+R+^+S+T+U+M.V+W+q.O.X+Y+:.:.:.:.:.:.u.] . . . . . . ",
". . . . . / 4+Z+2+k+U.`+ @V.W.X.Y.Z.`. +.+.+.+P+.@+@@@#@$@f+%@&@*@:.:.:.:.:.:.:.=@. . . . . . . ",
". . . . . / K+~+-@;@>@( ,@'@] H+)@m+!@T.~+~+4+4+4+!@~@{@]@^@/@(@:.:.:.:.:.:.:._@:@. . . . . . . ",
". . . . . / 5+K+I+<@[@}@|@1@2@3@V.)@)@)@)@)@)@)@)@)@)@)@4@5@G+:.:.:.:.:.:.:.:.'+6@. . . . . . . ",
". . . . . / N+W.z m+7@8@9@a.B.0@a@b@L+p+{+V.K+o+o+z U.J+n+M+c@%._@:.:.:.:.:.:.d@*.. . . . . . . ",
". . . . . / 7+W.W.e@f@g@z+d+h@p.i@j@k@l@V.K+o+z U.U.J+n+4+~+T.P+m@G.i+:.:.:.n@o@*.. . . . . . . ",
". . . . . F.p@M+W.q@r@s@t@{.u@o.a.}+v@w@:@x@z U.J+n+4+4+~+T.I+!@m+y@z@A@n@:.G+B@*.. . . . . . . ",
". . . . . ^ {@C@q+6@D@E@F@G@:+H@I@[+$@J@K@d@L@Q+n+4+~+~+T.I+!@m+)@H+H+M@N@O@u.P@*.. . . . . . . ",
". . . . . . ] Q@P R@S@T@U@` V@:+z+=+W@O.X@:.G+Y@Z@q+T.I+I+!@m+)@H+3+Z+Z+z `@ #p+*.. . . . . . . ",
". . . . . . . O .#+#@###H $#` f 9.%#[+&#*#Q.:.n@O@=#O !@m+m+)@H+3+-#;#>#,#'#H+5+*.. . . . . . . ",
". . . . . . . . )#!#~#{#q ]#d t :+*+].^#J@E.:.:.:.i+A@o@{+H+H+3+Z+/#(#(#_#:#H+X.*.. . . . . . . ",
". . . . . . . . <#[#}#|#1#a 2#3#u u@U+4#%@h+:.:.:.:.<.G.+ 3+Z+Z+!+5#6#7#8#9#H+Y.*.. . . . . . . ",
". . . . . . . ] 0#a#b#c#U d#Z e m.u@e#f#%@*@:.n@G+d@g#h#z z z z z z z U.U.U.X.O+- . . . . . . . ",
". . . . . . . 1.i#j#k#l#C m#6.F@t@z+n#}+o#p#'+q#r#s#r+N+N+Y.] ] s+O+O+Z.7+7+t+t#@ . . . . . . . ",
". . . . . . . # u#v#w#x#d#k.s K.b++.a.q.X+y#z# @P@1.1.1.1.1.1.1.1.1.1.1.1.1.1.O ^ . . . . . . . ",
". . . . . . ^ A#B#5.r 5.C#d D#E#L.F#-+G#H#:.A@= . . . . . . . = * ^ . . . . . . . . . . . . . . ",
". . . . . . + I#J#K#I L#M#N#J ..+.].4#O#F+:.i+P#^ . . . . . O d@G.P . . . . . . . . . . . . . . ",
". . . . . . @ Q#R#S#T#U#V#W#..*+e#X#G#&@Q.:.:.G+# P . ^ = - '+n@=@. . . . . . . . . . . . . . . ",
". . . . . . - Y#Y#Z#`#y  $.$+$e#-+;+J@*@:.:.:.:._@u.*.d@'+i+:.G+@ . . . . . . . . . . . . . . . ",
". . . . . ] @$#$@$/ = . @ $$%$&$;+o#/@:.:.:.:.:.:.:.:.:.:.:.:.%.z . . . . . . . . . . . . . . . ",
". . . . . . * @ ] . . . ^ y *$=$J@-$:.:.:.:.:.:.:.:.:.:.:.:.&.F.. . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . = ;$>$,$:.:.:.:.:.:.:.:.:.:.:.:.R.# ^ . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . @ '$)$!$g.:.:.:.:.:.:.:.:.:.G+~$^ . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . @ {$]$g.:.:.:.:.:.:.:.n@'+/ ^ . . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . F.d@R.:.:.:.:.:.<.'+=@O . . . . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . z @ =@G.G.G.H.* = ^ . . . . . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . . ^ P z . . . . . . . . . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
