package Kephra::API::Extension;
$VERSION = '0.00';

=head1 NAME

Kephra::API::Extension - Kephra's API for extentions (plugins)

=head1 DESCRIPTION

Not yet specced but extention will be installed and uninstalled
(not just copied) loaded when Kephra starts. They can extend the editor
in any way since they can mount functions to any event and provide new
menus, menu items even whole modules.

=cut

use strict;

sub install {}
sub uninstall {}

sub load_all {}
sub load {}
sub unload {}
sub is_loaded {}

1;