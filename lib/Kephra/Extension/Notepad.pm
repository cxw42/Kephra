package Kephra::Extension::Notepad;
our $VERSION = '0.08';

use strict;
use warnings;
use Wx qw(
	wxDEFAULT wxNORMAL wxLIGHT
	wxTE_MULTILINE wxTE_LEFT 
	wxFONTSTYLE_NORMAL wxFONTWEIGHT_NORMAL
	WXK_ESCAPE WXK_F3 WXK_F4 WXK_F5
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
			my $ep = Kephra::App::EditPanel::_ref();
			if ($key == WXK_ESCAPE) {
				Wx::Window::SetFocus( $ep );
			} elsif ($key == WXK_F3) {
				if ($event->ControlDown) {
					my $sel = $notepad->GetSelectedText;
					$event->ShiftDown
						? Kephra::Edit::Search::set_replace_item($sel)
						: Kephra::Edit::Search::set_find_item($sel);
				}
			} elsif ($key == WXK_F4) {
				Wx::Window::SetFocus( $ep );
				switch_visibility() if $event->ControlDown;
			} elsif ($key == WXK_F5) {
				my ( $sel_beg, $sel_end ) = $notepad->GetSelection;
				my $code = $sel_beg == $sel_end
					? $notepad->GetText
					: $notepad->GetSelectedText;
				my $result = eval $code;
				$result = $@ if $@;
				Kephra::Extension::Output::output($result);
			}
			$event->Skip;
	});	

	Kephra::API::EventTable::add_call
		( 'app.splitter.right.changed', 'extension_notepad', sub {
			if ( get_visibility() and not _splitter()->IsSplit() ) {
				show( 0 );
				return;
			}
			save_size();
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
		open my $FH, '>', $file_name;
		print $FH _ref()->GetText;
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
