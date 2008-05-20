package Kephra::App::MainToolBar;
use strict;
use warnings;

our $VERSION = '0.07';


sub _ref { Kephra::App::ToolBar::_ref('main', $_[0]) }
sub _config{ $Kephra::config{app}{toolbar}{main} }

sub create {
	return until get_visibility();
	my $frame = Kephra::App::Window::_ref();
	my $bar = $frame->GetToolBar;
	$bar->Destroy if $bar;          # destroy old toolbar if there any
	_ref( $frame->CreateToolBar );
	my $bar_def = Kephra::Config::File::load_from_config_node_data( _config() );
	unless ($bar_def) {
		$bar_def = Kephra::Config::Tree::get_subtree
			( Kephra::Config::Default::toolbars(), 'main_toolbar');
	}
	Kephra::App::ToolBar::create( 'main', $bar_def );
}
sub destroy { Kephra::App::ToolBar::destroy ('main') }

sub get_visibility    { _config()->{visible} }
sub switch_visibility { _config()->{visible} ^= 1; show(); }
sub show {
	if ( get_visibility() ){
		create()
	} else {
		_ref()->Destroy;
		Kephra::App::Window::_ref()->SetToolBar(undef);
	}
}

1;
