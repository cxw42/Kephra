#!/usr/bin/perl -w
#
# Compile Testing for Kephra
#
use strict;
use warnings;
BEGIN {
	$| = 1;
	unshift @INC, './lib', '../lib';
}

use Test::More;
use Test::Script;
use Test::NoWarnings;
#use Test::Exception;

use File::Find qw(find);
my @required_modules = qw(Cwd File::Find File::Spec::Functions Config::General YAML::Tiny);
my @kephra_modules;
find( sub {
    return if not -f $_ or $_ !~ /\.pm$/;
    my $module = $File::Find::name;
    $module =~ s{lib/}{};
    $module =~ s{\.pm}{};
    $module =~ s{/}{::}g;
    return if $module eq 'Kephra::Edit::Search';
    push @kephra_modules, $module;
}, 'lib'); # print "@modules"; #use Data::Dumper; # diag Dumper \@modules;

my $tests = 4 + @required_modules + @kephra_modules;
plan tests => $tests;

ok( $] >= 5.006, 'Your perl is new enough' );
use_ok('Kephra', 'main module compiles');
require_ok($_) for @required_modules, @kephra_modules;
cmp_ok( scalar(@kephra_modules), '>', 61, 'more then 61 Kephra modules found' );

# check the starter
# script_compiles_ok('bin/kephra');

#SKIP: {  #skip(2);    #skip(1);  #}
#TODO: {    #ok( 0, 'todo' );  #}

exit(0);
