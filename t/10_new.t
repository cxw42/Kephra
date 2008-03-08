#!/usr/bin/perl -w

# Construct a Kephra object, but don't start it

use strict;
BEGIN {
	$| = 1;
}

use Test::More tests => 1;
use Kephra;

# Create the new Kephra object
my $kephra = Kephra->new;
isa_ok( $kephra, 'Kephra' );

exit(0);
