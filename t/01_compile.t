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
my @modules;

find(\&get_module, 'lib');


sub get_module {
    return if not -f $_ or $_ !~ /\.pm$/;

    my $module = $File::Find::name;
    $module =~ s{lib/}{};
    $module =~ s{\.pm}{};
    $module =~ s{/}{::}g;
    push @modules, $module;
}

#use Data::Dumper;
# diag Dumper \@modules;

plan tests => 2 + @modules;

ok( $] >= 5.006, 'Your perl is new enough' );
foreach my $module (@modules) {
    require_ok($module);
}
cmp_ok( scalar(@modules), '>', 50, 'at least 50 modules found' );

# check the starter
#script_compiles_ok('bin/kephra');

exit(0);
