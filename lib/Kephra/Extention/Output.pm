package Kephra::Extention::Output;
our $VERSION = '0.04';

use strict;
use warnings;

use Wx qw(
	wxDEFAULT wxNORMAL wxLIGHT    
	wxTE_MULTILINE wxTE_READONLY wxTE_LEFT
	wxFONTFAMILY_DEFAULT wxFONTFAMILY_TELETYPE 
	wxFONTSTYLE_NORMAL wxFONTWEIGHT_NORMAL
);
use Wx::Perl::ProcessStream qw( EVT_WXP_PROCESS_STREAM_STDOUT
	EVT_WXP_PROCESS_STREAM_STDERR EVT_WXP_PROCESS_STREAM_EXIT  
);


sub _ref { 
	if ($_[0]) { $Kephra::app{panel}{output} = $_[0] }
	else       { $Kephra::app{panel}{output} } 
}
sub _config { $Kephra::config{app}{panel}{output} }

sub init {}

sub create {
	my $win = Kephra::App::Window::_ref();
	my $output_panel = Wx::TextCtrl->new($win, -1, '', [-1,-1], [-1,75],
			wxTE_MULTILINE | wxTE_READONLY | wxTE_LEFT );
	_ref($output_panel);
	$output_panel->SetBackgroundColour( Kephra::Config::color('000000') );
	$output_panel->SetForegroundColour( Kephra::Config::color('FFFFFF') );
	#my $caret = Wx::Caret->new($output_panel, 0, 0);
	#$caret->SetSize(0,0);
	#$output_panel->SetCaret( $caret );
	$output_panel->SetFont( Wx::Font->new
		( _config()->{font_size}, wxFONTSTYLE_NORMAL, wxNORMAL, wxLIGHT, 0, 'Terminal' )
	);
	EVT_WXP_PROCESS_STREAM_STDOUT( $win, sub { 
		my ($self, $event) = @_;
		output($event->GetLine."\n");
		$event->Skip(1);
	} );
	EVT_WXP_PROCESS_STREAM_STDERR( $win, sub {
		my ($self, $event) = @_;
		output($event->GetLine."\n");
		$event->Skip(1);
	} );
	EVT_WXP_PROCESS_STREAM_EXIT  ( $win, sub {
		my ($self, $event) = @_;
		$event->GetProcess->Destroy;
		$event->Skip(1);
	} );
	$output_panel->Show( get_visibility() );
	$output_panel;
}

sub get_visibility    { _config()->{visible} }
sub switch_visibility {
	my $panel = _ref();
	my $v = _config()->{visible} = $panel->IsShown ^ 1;
	$panel->Show( $v );
	Kephra::App::Window::_ref()->Layout;
}

sub output { 
	my $panel = _ref();
	$panel->AppendText( @_ );
}

sub run {
	my $win = Kephra::App::Window::_ref();
	my $doc = Kephra::Document::_get_current_file_path();
	switch_visibility() unless get_visibility();
	Kephra::File::save_current();
	if ($doc) {
		my $proc = _ref()->{process} = Wx::Perl::ProcessStream->OpenProcess
			(qq~perl "$doc"~ , 'Output-Extention', $win);
		_ref()->Clear;
		if (not $proc) {
			#$run_this_menu->Enable(1);
			#$run_menu->Enable(1);
			#$stop_menu->Enable(0);
		}
	} else {
		Kephra::App::StatusBar::info_msg(
			$Kephra::localisation{app}{menu}{document} . ' ' . 
			$Kephra::localisation{app}{general}{untitled} . "\n" );
	}
}

sub stop {
	#_ref()->{process}->TerminateProcess;
}

sub save {}

1;
