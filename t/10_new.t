#!/usr/bin/perl -w

# Construct a Kephra object, but don't start it

use strict;
BEGIN {
	$| = 1;
	push @INC, 'lib';
}

use Test::More tests => 2;
use Test::NoWarnings;
use Kephra;

#File::Spec->catdir($basedir, 'config');
#$Kephra::temp{path}{config} = './share/config';
#$Kephra::temp{path}{help} = './share/help';

$Kephra::STANDALONE = 'dev';

unlink 'share/config/global/autosaved.conf';
unlink 'share/config/global/autosaved.conf~';

# Create the new Kephra object
my $kephra = Kephra->new;
isa_ok( $kephra, 'Kephra' );

exit(0);
