#!/usr/bin/perl 
use strict;
use warnings;

BEGIN { 
    unshift @INC, 'lib';
    #chdir 'base';
}

require Kephra;

$Kephra::STANDALONE = 'dev';
Kephra->new->MainLoop;

#use FindBin;
#$ENV{KEPHRA_DEV_START} = 1;
#use File::Spec::Functions qw(catfile);
#my $lib = catfile( $FindBin::Bin, 'lib' );
#my $exe = catfile( $FindBin::Bin, 'bin', 'kephra' );
#system "$^X @ARGV -I$lib $exe";
