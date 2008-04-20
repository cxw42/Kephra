#!/usr/bin/perl -w

# Compile Testing for Kephra

use strict;
BEGIN {
	$| = 1;
	push @INC, 'lib';
}

use Test::More tests => 10;
use Test::Script;

ok( $] >= 5.006, 'Your perl is new enough' );

# check the app base module
use_ok('Kephra', 'Kephra does compile.' );

# check parts that are normally not loaded on start
require_ok('Kephra::Config::Embedded');
require_ok('Kephra::Dialog::Config');
require_ok('Kephra::Dialog::Exit');
require_ok('Kephra::Dialog::Info');
require_ok('Kephra::Dialog::Keymap');
require_ok('Kephra::Dialog::Notify');
require_ok('Kephra::Dialog::Search');

script_compiles_ok('bin/kephra');

exit(0);
