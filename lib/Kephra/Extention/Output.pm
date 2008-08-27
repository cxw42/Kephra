package Kephra::Extention::Output;
use strict;
use warnings;

use Wx qw(
	wxTE_MULTILINE wxTE_READONLY wxTE_LEFT 
	wxFONTFAMILY_TELETYPE wxFONTSTYLE_NORMAL wxFONTWEIGHT_NORMAL
);

our $VERSION = '0.01';

sub _ref { 
	if ($_[0]) { $Kephra::app{panel}{output} = $_[0] }
	else       { $Kephra::app{panel}{output} } 
}

sub create {
	my $win = Kephra::App::Window::_ref();
	my $output_panel =
		Wx::TextCtrl->new($win, -1, '', [-1,-1], [-1,75],
			wxTE_MULTILINE | wxTE_READONLY | wxTE_LEFT );
	_ref($output_panel);
	$output_panel->SetBackgroundColour( Kephra::Config::color('000000') );
	$output_panel->SetForegroundColour( Kephra::Config::color('FFFFFF') );
	my $caret = Wx::Caret->new($output_panel, 0, 0);
	$caret->SetSize(0,0);
	$output_panel->SetCaret( $caret );
	$output_panel->AppendText("STDOUT:\n\n");
	$output_panel;
}

sub get_visibility    { _ref()->IsShown }
sub switch_visibility { 
	_ref()->Show( _ref()->IsShown ^ 1 );
	Kephra::App::Window::_ref()->Layout;
}

sub run {
}

1;
