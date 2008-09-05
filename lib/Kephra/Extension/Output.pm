package Kephra::Extension::Output;
our $VERSION = '0.05';

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
	if (ref $_[0] eq 'Wx::TextCtrl') { $Kephra::app{panel}{output} = $_[0] }
	else                             { $Kephra::app{panel}{output} } 
}
sub _config { $Kephra::config{app}{panel}{output} }
sub _splitter { $Kephra::app{splitter}{bottom} }

sub init {}

sub create {
	my $win = Kephra::App::Window::_ref();
	my $output_panel = Wx::TextCtrl->new($win, -1, '', [-1,-1], [-1, -1],
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

	Kephra::API::EventTable::add_call('extension.output.run', 'panel_output', sub {
	});
	Kephra::API::EventTable::add_call
		( 'app.splitter.bottom.changed', 'extension_notepad', sub {
			show( 0 ) if get_visibility() and not _splitter()->IsSplit();
	});

	EVT_WXP_PROCESS_STREAM_STDOUT( $win, sub { 
		my ($self, $event) = @_;
		$event->Skip(1);
		output($event->GetLine."\n");
	} );
	EVT_WXP_PROCESS_STREAM_STDERR( $win, sub {
		my ($self, $event) = @_;
		$event->Skip(1);
		output($event->GetLine."\n");
	} );
	EVT_WXP_PROCESS_STREAM_EXIT  ( $win, sub {
		my ($self, $event) = @_;
		$event->Skip(1);
		$event->GetProcess->Destroy;
		Kephra::API::EventTable::trigger('extension.output.run');
	} );
	$output_panel->Show( get_visibility() );
	$output_panel;
}

sub get_visibility    { _config()->{visible} }
sub switch_visibility { show( get_visibility() ^ 1 ) }
sub show {
	my $visibile = shift;
	my $config = _config();
	$visibile  = $config->{visible} unless defined $visibile;
	my $win    = Kephra::App::Window::_ref();
	my $cpanel = $Kephra::app{panel}{center};
	my $output = _ref();
	my $splitter = _splitter();
	if ($visibile) {
		$splitter->SplitHorizontally( $cpanel, $output );
		$splitter->SetSashPosition( $win->GetSize->GetHeight - $config->{size}, 1);
	} else {
		save_size();
		$splitter->Unsplit();
		$splitter->Initialize( $cpanel );
	}
	$output->Show($visibile);
	$win->Layout;
	$config->{visible} = $visibile;
	Kephra::API::EventTable::trigger('extension.output.visible');
}

sub save { save_size() }
sub save_size {
	my $splitter = _splitter();
	return unless $splitter->IsSplit();
	_config()->{size} = 
		Kephra::App::Window::_ref()->GetSize->GetHeight - $splitter->GetSashPosition;
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
			(qq~perl "$doc"~ , 'Output-Extension', $win);
		_ref()->Clear;
		Kephra::API::EventTable::trigger('extension.output.run');
		if (not $proc) {
		}
	} else {
		Kephra::App::StatusBar::info_msg(
			$Kephra::localisation{app}{menu}{document} . ' ' . 
			$Kephra::localisation{app}{general}{untitled} . "\n" );
	}
}

sub is_running {
	my $proc = _ref()->{process};
	$proc->IsAlive if ref $proc eq 'Wx::Perl::ProcessStream::Process';
}

sub stop {
	my $proc = _ref()->{process};
	if (ref $proc eq 'Wx::Perl::ProcessStream::Process') {
		$proc->KillProcess;
		$proc->TerminateProcess;
		Kephra::API::EventTable::trigger('extension.output.run');
	}
}

1;