package Kephra::Extension::Notepad;
our $VERSION = '0.06';

use strict;
use warnings;
use Wx qw(
	wxDEFAULT wxNORMAL wxLIGHT
	wxTE_MULTILINE wxTE_LEFT 
	wxFONTSTYLE_NORMAL wxFONTWEIGHT_NORMAL
	WXK_ESCAPE WXK_F4
	wxSTC_WRAP_WORD wxSTC_STYLE_DEFAULT
);
use Wx::Event qw( EVT_KEY_DOWN );

sub _ref { 
	if (ref $_[0] eq 'Wx::StyledTextCtrl') { $Kephra::app{panel}{notepad} = $_[0] }
	else                                   { $Kephra::app{panel}{notepad} } 
}

sub _config { $Kephra::config{app}{panel}{notepad} }
sub _splitter { $Kephra::app{splitter}{right} }

sub create {
	my $win    = Kephra::App::Window::_ref();
	my $color  = \&Kephra::Config::color;
	my $indicator = Kephra::App::EditPanel::_config()->{indicator};
	my $config = _config();
	my $notepad = Wx::StyledTextCtrl->new( $win, -1, [-1,-1], [-1,-1] );
	$notepad->SetWrapMode(wxSTC_WRAP_WORD);
	$notepad->SetScrollWidth(210);
	$notepad->SetMarginWidth(0,0);
	$notepad->SetMarginWidth(1,0);
	$notepad->SetMargins(3,3);
	$notepad->SetCaretPeriod( $indicator->{caret}{period} );
	$notepad->SetCaretWidth( $indicator->{caret}{width} );
	$notepad->SetCaretForeground( &$color( $indicator->{caret}{color} ) );
	if ( $indicator->{selection}{fore_color} ne '-1' ) {
		$notepad->SetSelForeground
			( 1, &$color( $indicator->{selection}{fore_color} ) );
	}
	$notepad->SetSelBackground( 1, &$color( $indicator->{selection}{back_color}));

	$notepad->StyleSetFont( wxSTC_STYLE_DEFAULT, Wx::Font->new
		(_config()->{font_size}, wxDEFAULT, wxNORMAL, wxNORMAL, 0, 'Courier New') 
	);
	# load content
	my $file_name = $config->{content};
	if ($file_name) {
		$file_name = Kephra::Config::filepath($file_name);
		if (-e $file_name){
			open my $FILE, '<', $file_name;
			$notepad->AppendText( $_ ) while <$FILE>;
		}
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

	Kephra::API::EventTable::add_call
		( 'app.splitter.right.changed', 'extension_notepad', sub {
			show( 0 ) if get_visibility() and not _splitter()->IsSplit();
	});

	_ref($notepad);
	$notepad;
}

sub get_visibility    { _config()->{visible} }
sub switch_visibility { show( get_visibility() ^ 1 ) }
sub show {
	my $visibile = shift;
	my $config = _config();
	$visibile = $config->{visible} unless defined $visibile;
	my $win = Kephra::App::Window::_ref();
	my $main_panel = $Kephra::app{panel}{main};
	my $notepad  = _ref();
	my $splitter = _splitter();
	if ($visibile) {
		$splitter->SplitVertically( $main_panel, $notepad );
		$splitter->SetSashPosition( $win->GetSize->GetWidth - $config->{size}, 1);
	} else {
		save_size();
		$splitter->Unsplit();
		$splitter->Initialize( $main_panel );
	}
	$notepad->Show( $visibile );
	$win->Layout;
	$config->{visible} = $visibile;
	Kephra::API::EventTable::trigger('extension.notepad.visible');
}

sub note {
	show( 1 );
	Wx::Window::SetFocus( _ref() );
}

sub save {
	my $config = _config();
	my $file_name = $config->{content};
	if ($file_name) {
		$file_name = Kephra::Config::filepath($file_name);
		open my $FILE, '>', $file_name;
		print $FILE _ref()->GetText;
		close $FILE;
	}
	save_size();
}

sub save_size {
	my $splitter = _splitter();
	return unless $splitter->IsSplit();
	_config()->{size} = 
		Kephra::App::Window::_ref()->GetSize->GetWidth - $splitter->GetSashPosition;
}

1;
