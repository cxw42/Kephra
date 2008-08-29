package Kephra::Extention::Notepad;
our $VERSION = '0.01';

use strict;
use warnings;
use Wx qw(
	wxDEFAULT wxNORMAL wxLIGHT
	wxTE_MULTILINE wxTE_LEFT 
	wxFONTSTYLE_NORMAL wxFONTWEIGHT_NORMAL
	WXK_ESCAPE WXK_F4
);
use Wx::Event qw( EVT_KEY_DOWN );


sub _ref { 
	if ($_[0]) { $Kephra::app{panel}{notepad} = $_[0] }
	else       { $Kephra::app{panel}{notepad} } 
}

sub _config { $Kephra::config{app}{panel}{notepad} }

sub create {
	my $win = Kephra::App::Window::_ref();
	my $notepad = Wx::TextCtrl->new
		($win, -1, '', [-1,-1], [220,-1], wxTE_MULTILINE | wxTE_LEFT );
	_ref($notepad);
	$notepad->SetFont( Wx::Font->new
		( _config()->{font_size}, wxFONTSTYLE_NORMAL, wxNORMAL, wxLIGHT, 0, 'Courier New' )
	);
	my $file_name = _config()->{content};
	if ($file_name) {
		$file_name = Kephra::Config::filepath($file_name);
		open my $FILE, '<', $file_name;
		$notepad->AppendText( $_ ) while <$FILE>;
	}
	$notepad->Show( get_visibility() );
	EVT_KEY_DOWN( $notepad, sub {
		my ( $fi, $event ) = @_;
		my $key = $event->GetKeyCode;
		if ($key == WXK_ESCAPE) {
			Wx::Window::SetFocus( Kephra::App::EditPanel::_ref() );
		} elsif ($key == WXK_F4) {
			Wx::Window::SetFocus( Kephra::App::EditPanel::_ref() );
			switch_visibility() if $event->ControlDown;
		}
		$event->Skip;
	});
	
	$notepad;
}

sub get_visibility    { _config()->{visible} }
sub switch_visibility { 
	my $panel = _ref();
	my $v = _config()->{visible} = $panel->IsShown ^ 1;
	$panel->Show( $v );
	Kephra::App::Window::_ref()->Layout;
}

sub note {
	my $panel = _ref();
	my $v = _config()->{visible} = 1;
	$panel->Show( $v );
	Wx::Window::SetFocus( $panel );
	Kephra::App::Window::_ref()->Layout;
}

sub save { 
	my $file_name = _config()->{content};
	if ($file_name) {
		$file_name = Kephra::Config::filepath($file_name);
		open my $FILE, '>', $file_name;
		print $FILE _ref()->GetValue;
		close $FILE;
	}
}

1;
