my $fn = $ARGV[0];
open A, ">dump.armsim";
foreach ( `./arm.pl -D --readelf "$fn"` ) {
    m/^([0-9A-F]+):\s+\S+\s+([0-9A-F]+)/ or next;
    print A lc $1,"\t",lc $2,"\n";
}
close A;
open B, ">dump.objdump";
foreach ( `arm-uclinux-elf-objdump -D "$fn"` ) {
    m/^\s*([0-9a-f]+):\s+([0-9a-f]+)/ or next;
    print B lc $1,"\t",lc $2,"\n";
}
close B;
