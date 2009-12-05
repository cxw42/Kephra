package Kephra::App::MainToolBar;
our $VERSION = '0.09';

=head1 NAME

Kephra::App::MainToolBar - main toolbar of the app 

=head1 DESCRIPTION

=cut
use strict;
use warnings;

sub _ref    { Kephra::ToolBar::_ref( _name(), $_[0]) }
sub _name   { 'main' }
sub _ID     { _name().'_toolbar' }
sub _config { Kephra::API::settings()->{app}{toolbar}{main} }

sub create {
	return until get_visibility();
	my $frame = Kephra::App::Window::_ref();
	my $bar = $frame->GetToolBar;
	# destroy old toolbar if there any
	Kephra::ToolBar::destroy( _name() ) if $bar;
	_ref( $frame->CreateToolBar );
	my $bar_def = Kephra::Config::File::load_from_node_data( _config() );
	unless ($bar_def) {
		$bar_def = Kephra::Config::Tree::get_subtree
			( Kephra::Config::Default::toolbars(), _ID() );
	}
	Kephra::ToolBar::create( _name(), $bar_def );
}
sub destroy { Kephra::ToolBar::destroy ( _name() ) }

sub get_visibility    { _config()->{visible} }
sub switch_visibility { _config()->{visible} ^= 1; show(); }
sub show {
	if ( get_visibility() ){
		create()
	} else {
		Kephra::ToolBar::destroy( _name() );
		Kephra::App::Window::_ref()->SetToolBar(undef);
	}
}

1;
