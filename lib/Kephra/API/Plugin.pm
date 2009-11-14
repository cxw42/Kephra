package Kephra::API::Plugin;
our $VERSION = '0.00';

=head1 NAME

Kephra::API::Plugin - API to extend the App

=head1 DESCRIPTION

Not yet specced but extention will be installed and uninstalled
(not just copied) loaded when Kephra starts. They can extend the editor
in any way since they can mount functions to any event and provide new
menus, menu items even whole modules.

=cut

use strict;
use warnings;


sub install {}
sub uninstall {}

sub is_loaded {}
sub all_loaded {}
sub load_all {
	#require Kephra::Extention::Demo;
}
sub load {}
sub unload {}

1;
