#!/usr/bin/perl 
use strict;
use warnings;

use FindBin;
$ENV{KEPHRA_DEV_START} = 1;
use File::Spec::Functions qw(catfile);
my $lib = catfile( $FindBin::Bin, 'lib' );
my $exe = catfile( $FindBin::Bin, 'bin', 'kephra' );
system "$^X @ARGV -I$lib $exe";


