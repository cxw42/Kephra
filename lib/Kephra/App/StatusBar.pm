package Kephra::App::StatusBar;
use strict;
use warnings;

our $VERSION = '0.04';

use Wx::Event qw( EVT_LEFT_DOWN EVT_RIGHT_DOWN ); 


sub _ref    { $Kephra::app{statusbar} }
sub _item   { }
sub _config { $Kephra::config{app}{statusbar} }

sub create {
	# StatusBar settings, will be removed by stusbar config file
	$Kephra::temp{app}{status}{cursor}{index}    = 0;
	$Kephra::temp{app}{status}{selection}{index} = 1;
	$Kephra::temp{app}{status}{style}{index}     = 2;
	$Kephra::temp{app}{status}{tab}{index}       = 3;
	$Kephra::temp{app}{status}{EOL}{index}       = 4;
	$Kephra::temp{app}{status}{message}{index}   = 5;

	my $win = Kephra::App::Window::_ref();
	$win->CreateStatusBar(1);
	my $bar = $win->GetStatusBar;

	$bar->SetFieldsCount(6);
	if ( $^O eq 'linux' ) { $bar->SetStatusWidths( 90, 66, 60, 40, 70, -1 ) }
	else                  { $bar->SetStatusWidths( 66, 60, 50, 25, 32, -1 ) }
	$win->SetStatusBarPane($Kephra::temp{app}{status}{message}{index});

	EVT_LEFT_DOWN ( $bar,  \&left_click);
	EVT_RIGHT_DOWN( $bar,  \&right_click);

	Kephra::API::EventTable::add_call
		('caret.move',           'caret_status',\&caret_pos_info);
	Kephra::API::EventTable::add_call
		('document.text.change', 'info_msg',  \&refresh_info_msg);
	Kephra::API::EventTable::add_call
		('editpanel.focus',      'info_msg',  \&refresh_info_msg);

	show();
}


sub get_visibility { _config()->{'visible'} }
sub switch_visibility {
	_config()->{'visible'} ^= 1;
	show();
	Kephra::App::Window::_ref()->Layout();
}
sub show { Kephra::App::Window::_ref()->GetStatusBar->Show( get_visibility() ) }

sub right_click {
	return unless get_interactive();
	my ( $bar,    $event )  = @_;
	my ( $x,      $y )      = ( $event->GetX, $event->GetY );
	my $menu = \&Kephra::App::ContextMenu::get;
	if ( $^O eq 'linux' ) {
		if    ($x < 156) {}
		elsif ($x < 215) {$bar->PopupMenu( &$menu('status_syntaxmode'), $x, $y)}
		elsif ($x < 257) {$bar->PopupMenu( &$menu('status_tab'),        $x, $y)}
		elsif ($x < 326) {$bar->PopupMenu( &$menu('status_eol'),        $x, $y)}
		else             {$bar->PopupMenu( &$menu('status_info'),       $x, $y)}
	} else {
		if    ($x < 128) {}
		elsif ($x < 180) {$bar->PopupMenu( &$menu('status_syntaxmode'), $x, $y)}
		elsif ($x < 206) {$bar->PopupMenu( &$menu('status_tab')       , $x, $y)}
		elsif ($x < 241) {$bar->PopupMenu( &$menu('status_eol')       , $x, $y)}
		else             {$bar->PopupMenu( &$menu('status_info')      , $x, $y)}
	}
}


sub left_click {
	return unless get_interactive();
	my ( $bar,    $event )  = @_;
	my ( $x,      $y )      = ( $event->GetX, $event->GetY );
	my $menu = \&Kephra::App::ContextMenu::get;
	if ( $^O eq 'linux' ) {
		if    ($x < 156) {}
		elsif ($x < 215) {Kephra::Document::SyntaxMode::switch_auto()}
		elsif ($x < 256) {&Kephra::Document::switch_tab_mode}
		elsif ($x < 326) {&Kephra::App::EditPanel::switch_EOL_visibility}
		else             {next_file_info()}
	} else {
		if    ($x < 128) {}
		elsif ($x < 180) {Kephra::Document::SyntaxMode::switch_auto()}
		elsif ($x < 206) {&Kephra::Document::switch_tab_mode}
		elsif ($x < 241) {&Kephra::App::EditPanel::switch_EOL_visibility}
		else             {next_file_info()}
	}
}

sub get_interactive { _config()->{interactive} }
sub get_contextmenu_visibility { &get_interactive }
sub switch_contextmenu_visibility { _config()->{interactive} ^= 1 }


sub refresh_cursor {
	caret_pos_info();
	refresh_info_msg();
}

sub update_all {
	caret_pos_info();
	style_info();
	tab_info();
	EOL_info();
	info_msg();
}

sub caret_pos_info {
	my $frame  = Kephra::App::Window::_ref();
	my $ep     = Kephra::App::EditPanel::_ref();
	my $pos    = $ep->GetCurrentPos;
	my $line   = $ep->LineFromPosition($pos) + 1;
	my $lpos   = $ep->GetColumn($pos) + 1;
	my $cindex = $Kephra::temp{app}{status}{cursor}{index};
	my $sindex = $Kephra::temp{app}{status}{selection}{index};
	my ($value);

	# caret pos display
	if ( $line > 9999  or $lpos > 9999 ) {
		   $frame->SetStatusText( " $line : $lpos", $cindex ) }
	else { $frame->SetStatusText( "  $line : $lpos", $cindex ) }

	# selection or  pos % display
	my ( $sel_beg, $sel_end ) = $ep->GetSelection;
	unless ( $Kephra::temp{current_doc}{text_selected} ) {
		my $chars = $ep->GetLength;
		if ($chars) {
			my $value = int 100 * $pos / $chars + .5;
			$value = ' ' . $value if $value < 10;
			$value = ' ' . $value . ' ' if $value < 100;
			$frame->SetStatusText( "    $value%", $sindex );
		} else { $frame->SetStatusText( "    100%", $sindex ) }
		$Kephra::temp{edit}{selected} = 0;
	} else {
		if ( $ep->SelectionIsRectangle ) {
			my $x = abs int $ep->GetColumn($sel_beg) - $ep->GetColumn($sel_end);
			my $lines = 1 + abs int $ep->LineFromPosition($sel_beg)
				- $ep->LineFromPosition($sel_end);
			my $chars = $x * $lines;
			$lines = ' ' . $lines if $lines < 100;
			if ($lines < 10000) { $value = "$lines : $chars" }
			else                { $value = "$lines:$chars" }
			$frame->SetStatusText( $value , $sindex );
		} else {
			my $lines = 1 + $ep->LineFromPosition($sel_end)
						  - $ep->LineFromPosition($sel_beg);
			my $chars = $sel_end - $sel_beg - 
				($lines - 1) * $Kephra::temp{'current_doc'}{'EOL_length'};
			$lines = ' ' . $lines if $lines < 100;
			if ($lines < 10000) { $value = "$lines : $chars" }
			else                { $value = "$lines:$chars" }
			$frame->SetStatusText( $value, $sindex );
		}
		$Kephra::temp{edit}{selected} = 1;
	}
	#status_msg();
	#$sci->CallTipShow($pos-1, $match_before);
	#$sci->AutoCompShow(2,'ara arab aha')
}

sub style_info {
	my $style = shift;
	$style = Kephra::Document::SyntaxMode::_ID() unless defined $style;
	$style = Kephra::Config::Localisation::strings()->{dialog}{general}{none}
		unless defined $style;
	Kephra::App::Window::_ref()->SetStatusText
		( ' ' . $style, $Kephra::temp{app}{status}{style}{index} );
}

sub tab_info {
	my $win   = Kephra::App::Window::_ref();
	my $mode  = Kephra::App::EditPanel::_ref()->GetUseTabs;
	my $index = $Kephra::temp{app}{status}{tab}{index};
	$mode = 0 unless $mode;
	$mode ? $win->SetStatusText( " HT", $index ) 
		  : $win->SetStatusText( " ST", $index );
}

sub EOL_info {
	my ( $mode, $msg ) = shift;
	$mode = Kephra::Document::get_attribute('EOL') if !$mode;
	if ( !$mode or $mode eq 'none' or $mode eq 'no' )  {
		$msg = Kephra::Config::Localisation::strings()->{dialog}{general}{none};
	}
	elsif ( $mode eq 'cr'    or $mode eq 'mac' ) { $msg = " Mac" }
	elsif ( $mode eq 'lf'    or $mode eq 'lin' ) { $msg = "Linux" }
	elsif ( $mode eq 'cr+lf' or $mode eq 'win' ) { $msg = " Win" }
	Kephra::App::Window::_ref()->SetStatusText
		( $msg, $Kephra::temp{app}{status}{EOL}{index} );
}

# info messages

sub status_msg { info_msg(@_) }
sub info_msg {
	return unless $_[0];
	Kephra::App::Window::_ref()->SetStatusText
		( shift, $Kephra::temp{app}{status}{message}{index} );
}
sub refresh_info_msg  { refresh_file_info() }

sub info_msg_nr {
	my $nr = shift;
	if (defined $nr) { _config()->{msg_nr} = $nr}
	else             { _config()->{msg_nr} }
}

sub next_file_info {
	my $info_nr = _config()->{msg_nr};
	$info_nr = $info_nr >= 2 ? 0 : $info_nr + 1;
	set_info_msg_nr($info_nr);
}

sub set_info_msg_nr {
	my $info_nr = shift || 0;
	info_msg_nr($info_nr);
	refresh_file_info();
}

sub refresh_file_info {
	my $msg = info_msg_nr() ? _get_file_info( _config()->{msg_nr} ) : '';
	Kephra::App::Window::_ref()->GetStatusBar->SetStatusText
		($msg, $Kephra::temp{app}{status}{message}{index} );
}

sub _get_file_info {
	my $selector = shift;
	return '' unless $selector;
	my $l10 = Kephra::Config::Localisation::strings()->{app}{status};

	# show how big file is
	if ( $selector == 1 ) {
		my $ep = Kephra::App::EditPanel::_ref();

		return sprintf ' %s: %s   %s: %s',
			$l10->{chars}, _dotted_number( $ep->GetLength ),
			$l10->{lines}, _dotted_number( $ep->GetLineCount );

	# show how old file is
	} elsif ( $selector == 2 ) {
		my $file_name = Kephra::Document::get_file_path();
		if ($file_name) {
			my @time = localtime( $^T - ( -M $file_name ) * 86300 );
			return sprintf ' %s: %02d:%02d - %02d.%02d.%d', $l10->{last_change},
				$time[2], $time[1], $time[3], $time[4] + 1, $time[5] + 1900;
		} else {
			my @time = localtime;
			return sprintf ' %s: %02d:%02d - %02d.%02d.%d', $l10->{now_is},
				$time[2], $time[1], $time[3], $time[4] + 1, $time[5] + 1900;
		}
	}
}

sub _dotted_number {
	local $_ = shift;
	1 while s/^(\d+)(\d{3})/$1.$2/;
	return $_;
}

1;
