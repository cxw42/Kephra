package Kephra::Extention::Output;
our $VERSION = '0.02';

use strict;
use warnings;

use Wx qw(
	wxDEFAULT wxNORMAL wxLIGHT
	wxTE_MULTILINE wxTE_READONLY wxTE_LEFT 
	wxFONTFAMILY_TELETYPE wxFONTSTYLE_NORMAL wxFONTWEIGHT_NORMAL
);
use Wx::Perl::ProcessStream qw( EVT_WXP_PROCESS_STREAM_STDOUT
	EVT_WXP_PROCESS_STREAM_STDERR EVT_WXP_PROCESS_STREAM_EXIT  
);


sub _ref { 
	if ($_[0]) { $Kephra::app{panel}{output} = $_[0] }
	else       { $Kephra::app{panel}{output} } 
}

sub init {
	my $win = Kephra::App::Window::_ref();
}

sub create {
	my $win = Kephra::App::Window::_ref();
	my $output_panel = Wx::TextCtrl->new($win, -1, '', [-1,-1], [-1,75],
			wxTE_MULTILINE | wxTE_READONLY | wxTE_LEFT );
	_ref($output_panel);
	$output_panel->SetBackgroundColour( Kephra::Config::color('000000') );
	$output_panel->SetForegroundColour( Kephra::Config::color('FFFFFF') );
	my $caret = Wx::Caret->new($output_panel, 0, 0);
	$caret->SetSize(0,0);
	$output_panel->SetCaret( $caret );
	$output_panel->SetFont( 
		Wx::Font->new( 10, wxFONTFAMILY_TELETYPE, wxNORMAL, wxLIGHT, 0, 'Terminal' ) 
	);
	EVT_WXP_PROCESS_STREAM_STDOUT( $win, sub { 
		my ($self, $event) = @_;
		$event->Skip(1);
		my $process = $event->GetProcess;
		my $line = $event->GetLine;
		output("$line\n");
	} );
	EVT_WXP_PROCESS_STREAM_STDERR( $win, sub {
		my ($self, $event) = @_;
		$event->Skip(1);
		my $process = $event->GetProcess;
		my $line = $event->GetLine;
		output("$line\n");	} );
	EVT_WXP_PROCESS_STREAM_EXIT  ( $win, sub {  } );
	$output_panel;
}

sub get_visibility    { _ref()->IsShown }
sub switch_visibility { 
	_ref()->Show( _ref()->IsShown ^ 1 );
	Kephra::App::Window::_ref()->Layout;
}

sub output { 
	my $panel = _ref();
	$panel->Clear;
	$panel->AppendText( @_ );
}

sub run {
	my $win = Kephra::App::Window::_ref();
	my $doc = Kephra::Document::_get_current_file_path();
	Kephra::File::save_current();
	if ($doc) {
		my $proc = Wx::Perl::ProcessStream->OpenProcess("perl $doc", 'Output-Extention', $win);
	} else {
		Kephra::App::StatusBar::info_msg(
			$Kephra::localisation{app}{menu}{document} . ' ' . 
			$Kephra::localisation{app}{general}{untitled} . "\n" );
	}
}

1;
