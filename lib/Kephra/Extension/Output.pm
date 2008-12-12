package Kephra::Extension::Output;
our $VERSION = '0.07';

use strict;
use warnings;

use Cwd();
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
sub _config   { $Kephra::config{app}{panel}{output} }
sub _splitter { $Kephra::app{splitter}{bottom} }

sub init {}

sub create {
	my $win = Kephra::App::Window::_ref();
	my $output_panel = Wx::TextCtrl->new (
		$win, -1, '', [-1,-1], [-1, -1], wxTE_MULTILINE|wxTE_READONLY|wxTE_LEFT
	);
	_ref($output_panel);
	my $config = _config();
	my $color = \&Kephra::Config::color;
	$output_panel->SetForegroundColour( &$color( $config->{fore_color} ) );
	$output_panel->SetBackgroundColour( &$color( $config->{back_color} ) );

	#my $caret = Wx::Caret->new($output_panel, 0, 0);
	#$caret->SetSize(0,0);
	#$output_panel->SetCaret( $caret );
	$output_panel->SetFont( Wx::Font->new
		($config->{font_size}, wxFONTSTYLE_NORMAL, wxNORMAL, wxLIGHT, 0, 'Terminal')
	);

	Kephra::API::EventTable::add_call('extension.output.run', 'panel_output', sub {
	});
	Kephra::API::EventTable::add_call
		( 'app.splitter.bottom.changed', 'extension_notepad', sub {
			if ( get_visibility() and not _splitter()->IsSplit() ) {
				show( 0 );
				return;
			}
			save_size();
	});

	EVT_WXP_PROCESS_STREAM_STDOUT( $win, sub { 
		my ($self, $event) = @_;
		$event->Skip(1);
		say( $event->GetLine );
	} );
	EVT_WXP_PROCESS_STREAM_STDERR( $win, sub {
		my ($self, $event) = @_;
		$event->Skip(1);
		say( $event->GetLine );
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
sub ensure_visibility { switch_visibility() unless get_visibility() }
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


sub clear { _ref()->Clear }
sub print { _ref()->AppendText( @_ ) if @_ }
sub say   { &print; _ref()->AppendText( "\n" ) }
sub output { 
	_config()->{append}
		? print( "\n\n" )
		: clear();
	print( @_ );
}


sub run {
	my $win = Kephra::App::Window::_ref();
	my $doc = Kephra::Document::get_file_path();
	my $cmd = _config->{interpreter_path};
	my $dir = $Kephra::config{file}{current}{directory};
	ensure_visibility();
	Kephra::File::save_current();
	if ($doc) {
		my $dir = Cwd::cwd();
		chdir $dir;
		my $proc = _ref()->{process} = Wx::Perl::ProcessStream->OpenProcess
			(qq~"$cmd" "$doc"~ , 'Output-Extension', $win); # -I$dir 
		chdir $dir;
		output();
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