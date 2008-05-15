#!/usr/bin/perl -w

# Compile Testing for Kephra

use strict;
BEGIN {
	$| = 1;
	unshift @INC, './lib';
}

use Test::More tests => 14;
use Test::Script;

ok( $] >= 5.006, 'Your perl is new enough' );

# check the app base module
use_ok('Kephra', 'Kephra does compile.' );

# check parts that are normally not loaded on start
require_ok('Kephra::Config::Default::Global_Settings');
require_ok('Kephra::Config::Default::CommandList');
require_ok('Kephra::Config::Default::Localisation');
require_ok('Kephra::Config::Default::MainMenu');
require_ok('Kephra::Config::Default::ContextMenus');
require_ok('Kephra::Config::Default::ToolBars');
require_ok('Kephra::Dialog::Config');
require_ok('Kephra::Dialog::Exit');
require_ok('Kephra::Dialog::Info');
require_ok('Kephra::Dialog::Keymap');
require_ok('Kephra::Dialog::Notify');
require_ok('Kephra::Dialog::Search');

# check the starter
#script_compiles_ok('bin/kephra');

exit(0);
