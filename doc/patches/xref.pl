#!usr/bin/perl

use strict;
use warnings;

#config
    my $dirPath = '.';
    my @searchStrings = qw( subName01 subName02 );
    my $fileFilterPattern = '\.pl$';
#/config

opendir(my $dirFH, $dirPath) or die $!;

for my $fileName (readdir($dirFH)) {
    next if -d $fileName;
    next if $fileName !~ m/$fileFilterPattern/;
    print "$fileName:\n";
    
    open(my $fileFH, "<", "$dirPath\\$fileName") or die $!;
    
    while (<$fileFH>) {
        chomp (my $row = $_);
        for my $string (@searchStrings) {
            if ($row =~ m/^[^#]*\b$string\b/) {
                print "\t$string (line $.: \"$row\")\n";
            }
        }
    }
    close $fileFH or die $!;
}
closedir $dirFH or die $!;