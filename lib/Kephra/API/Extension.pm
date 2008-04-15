package Kephra::API::Extension;
$VERSION = '0.00';

=head1

Kephra::API::Extension - Kephra's API for extentions (plugins)

=cut

use strict;

sub install {}
sub uninstall {}

sub load_all {}
sub load {}
sub unload {}
sub is_loaded {}

1;