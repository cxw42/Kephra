package Kephra::Show;
use strict;

our $VERSION = '0.13';


###################
# open config files
###################
# open file will full absolut path
sub _open_config{ 
	Kephra::Document::Internal::add( shift );
	Kephra::Document::set_attribute('config_file',1);
	Kephra::App::TabBar::refresh_current_label();
}

#
sub localisation_file{ 
	_open_config( Kephra::Config::filepath('localisation', "$_[0].conf") )
}
sub syntaxmode_file  { 
	_open_config( Kephra::Config::filepath('syntaxhighlighter', "$_[0].pm") )
}
sub interface_file   {
	my $item = shift;
	return unless exists $Kephra::config{app}{$item};
	my $file = $Kephra::config{app}{$item}{file};
	$file = $Kephra::config{app}{$item}{defaultfile} if $item eq 'contextmenu';
	$file = $Kephra::config{app}{toolbar}{all}{defaultfile} if $item eq 'toolbar';
	_open_config( Kephra::Config::filepath( $file ) );
}

sub templates_file     {
 my $config = $Kephra::config{file}{templates}; 
	_open_config 
		( Kephra::Config::filepath( $config->{directory}, $config->{file} ) );
}

###################
# open help files
###################

sub _hf { 
	Kephra::Document::Internal::add ( 
		File::Spec->catfile( $Kephra::temp{path}{help}, shift )
	)
}

sub welcome              { _hf $Kephra::config{texts}{welcome}}
sub version_text         { _hf $Kephra::config{texts}{version}}
sub licence_gpl          { _hf $Kephra::config{texts}{license}}
sub feature_tour         { _hf $Kephra::config{texts}{feature}}
sub advanced_tour        { _hf $Kephra::config{texts}{special}}
sub navigation_guide     { _hf $Kephra::config{texts}{navigation}}
sub credits              { _hf $Kephra::config{texts}{credits}}
sub keyboard_map         { _hf $Kephra::config{texts}{keymap}}

1;
