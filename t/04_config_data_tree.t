#!/usr/bin/perl -w
#
# testing Kephra::Config::Tree
#

BEGIN {
	chdir '..' if -d '../t';
	$| = 1;
	unshift @INC, './lib', '../lib';
}

use strict;
use warnings;

use Test::More tests => 1;
use Test::NoWarnings;


# API to test
# sub subtree {# get /a/sub/tree/
# sub copy {   # get a deep copy 
# sub merge {  # if defined left else right , merge both structures
# sub update { # keep shape of right data structure
# sub diff {   # return diffs


exit(0);