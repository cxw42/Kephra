package Kephra::Plugin::Output;
our $VERSION = '0.08';

use strict;
use warnings;
use Cwd();
use Wx::Perl::ProcessStream qw( 
	EVT_WXP_PROCESS_STREAM_STDOUT
	EVT_WXP_PROCESS_STREAM_STDERR
	EVT_WXP_PROCESS_STREAM_EXIT
);
use Wx::DND;

my $output;
sub _ref { if (ref $_[0] eq 'Wx::TextCtrl') {$output = $_[0]} else {$output} }
sub _config   { $Kephra::config{app}{panel}{output} }
sub _splitter { $Kephra::app{splitter}{bottom} }

sub init {}

sub create {
	my $win = Kephra::App::Window::_ref();
	my $edit = Kephra::App::EditPanel::_ref();
	my $output;
	if (_ref()) {$output = _ref()}
	else {
		$output = Wx::TextCtrl->new
			($win, -1,'', [-1,-1], [-1,-1],
			&Wx::wxTE_PROCESS_ENTER | &Wx::wxTE_MULTILINE | &Wx::wxTE_LEFT);
	}
	_ref($output);
	my $config = _config();
	my $color = \&Kephra::Config::color;
	$output->SetForegroundColour( &$color( $config->{fore_color} ) );
	$output->SetBackgroundColour( &$color( $config->{back_color} ) );
	$output->SetFont( Wx::Font->new
		($config->{font_size}, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxNORMAL, &Wx::wxLIGHT, 0,
		$config->{font_family})
	);
	$output->SetEditable(0);

	Kephra::API::EventTable::add_call('plugin.output.run', 'panel_output', sub {
	});
	Kephra::API::EventTable::add_call
		( 'app.splitter.bottom.changed', 'plugin_notepad', sub {
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
		Kephra::API::EventTable::trigger('plugin.output.run');
	} );
	Wx::Event::EVT_TEXT_ENTER( $edit, $edit, sub {
		my $selection = $edit->GetStringSelection();
		return unless $selection;
		wxTheClipboard->Open;
		wxTheClipboard->SetData( Wx::TextDataObject->new( $selection ) );
		wxTheClipboard->Close;
	} );

	$output->Show( get_visibility() );
	$output;
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
		$splitter->SetSashPosition( -1*$config->{size}, 1);
	} else {
		$splitter->Unsplit();
		$splitter->Initialize( $cpanel );
	}
	$output->Show($visibile);
	$win->Layout;
	$config->{visible} = $visibile;
	Kephra::API::EventTable::trigger('plugin.output.visible');
}

sub save { save_size() }
sub save_size {
	my $splitter = _splitter();
	return unless $splitter->IsSplit();
	my $wh=Kephra::App::Window::_ref()->GetSize->GetHeight;
	_config()->{size} = -1*($wh-($wh-$splitter->GetSashPosition));
}


sub clear {
	_ref()->Clear;
	if (Wx::wxMAC()) {_ref()->SetFont
		( Wx::Font->new(_config()->{font_size}, &Wx::wxFONTSTYLE_NORMAL,
		  &Wx::wxNORMAL, &Wx::wxLIGHT, 0, _config()->{font_family})
	)}
}
sub print { _ref()->AppendText( @_ ) if @_ }
sub say   { &print; _ref()->AppendText( "\n" ) }
sub new_output {
	ensure_visibility();
	_config()->{append}
		? print( "\n\n" )
		: clear();
	&print( @_ );
}

# 
sub display_inc { new_output('@INC:'."\n"); &say("  -$_") for @INC }

# to be outsourced into interpreter plugin
sub run {
	my $win = Kephra::App::Window::_ref();
	my $doc = Kephra::Document::Data::get_file_path();
	my $cmd = _config->{interpreter_path};
	my $dir = $Kephra::config{file}{current}{directory};
	Kephra::File::save();
	if ($doc) {
		my $dir = Cwd::cwd();
		chdir $dir;
		my $proc = _ref()->{process} = Wx::Perl::ProcessStream->OpenProcess
			(qq~"$cmd" "$doc"~ , 'Interpreter-Plugin', $win); # -I$dir
		chdir $dir;
		new_output();
		Kephra::API::EventTable::trigger('plugin.output.run');
		if (not $proc) {}
	} else {
		my $l18n = Kephra::Config::Localisation::strings()->{app};
		Kephra::App::StatusBar::info_msg
			($l18n->{menu}{document}.' '.$l18n->{general}{untitled}."\n" );
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
		Kephra::API::EventTable::trigger('plugin.output.run');
	}
}

1;
