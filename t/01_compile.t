#!/usr/bin/perl -w

# Compile Testing for Kephra

use strict;
BEGIN {
	$| = 1;
	unshift @INC, './lib';
}

use File::Find qw(find);

use Test::More;
use Test::Script;
use Test::NoWarnings;
#use Test::Exception;

my @modules;
#find(\&get_module, 'lib');
sub get_module {
    return if not -f $_ or $_ !~ /\.pm$/;

    my $module = $File::Find::name;
    $module =~ s{lib/}{};
    $module =~ s{\.pm}{};
    $module =~ s{/}{::}g;
    push @modules, $module;
}

#use Data::Dumper; # diag Dumper \@modules;
my $tests = 3;# + @modules
plan tests => $tests;

ok( $] >= 5.006, 'Your perl is new enough' );
use_ok('Kephra');

SKIP:{
    ;
    #skip(2);
    #cmp_ok( scalar(@modules), '>', 58, 'at least 58 modules found' );
    #foreach my $module (@modules) {
    #    require_ok($module);
    #}
    #skip(1);
    #script_compiles_ok('bin/kephra');
}


# check the starter
TODO: {
    ;
}

#exit(0);
