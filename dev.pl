#!/usr/bin/perl 
use strict;
use warnings;

$ENV{KEPHRA_DEV_START} = 1;
use File::Spec::Functions qw(catfile);
system "$^X @ARGV -Ilib " . catfile( 'bin', 'kephra');


