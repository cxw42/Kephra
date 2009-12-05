package Kephra::App::MenuBar;
our $VERSION = 0.07;

=head1 NAME

Kephra::App::MenuBar - main menu of the app 

=head1 DESCRIPTION

=cut

use strict;
use warnings;

my $bar;
sub _ref { $bar = ref $_[0] eq 'Wx::MenuBar' ? $_[0] : $bar }

sub create {
	my $menubar_def = Kephra::Config::File::load_from_node_data
		( Kephra::API::settings()->{app}{menubar} );
	unless ($menubar_def) {
		$menubar_def = Kephra::Config::Default::mainmenu();
	}
	my $menubar    = Wx::MenuBar->new();
	my $m18n = Kephra::Config::Localisation::strings()->{app}{menu};
	my ($pos, $menu_name);
	for my $menu_def ( @$menubar_def ){
		for my $menu_id (keys %$menu_def){
			# removing the menu command if there is one
			$pos = index $menu_id, ' ';
			if ($pos > -1){
				if ('menu' eq substr $menu_id, 0, $pos ){
					$menu_name = substr ($menu_id, $pos+1);
				# ignoring menu structure when command other that menu or blank
				} else { next }
			} else { 
				$menu_name = $menu_id;
			}
			$menubar->Append(
				Kephra::Menu::create_static( $menu_name, $menu_def->{$menu_id}),
				$m18n->{label}{$menu_name}
			);
		}
	}
	Kephra::App::Window::_ref()->SetMenuBar($menubar);
	_ref($menubar);
}

1;
