package Kephra::App::StatusBar;
our $VERSION = '0.07';

use strict;
use warnings;

my (@fields, @abs_border_x, %index, %width);
my $bar;
sub _ref    { $bar = ref $_[0] eq 'Wx::StatusBar' ? $_[0] : $bar }
sub _config { $Kephra::config{app}{statusbar} }
sub _item   { $fields[$_[0]] }
sub _set_text {
	my ($msg, $nr) = @_;
	my $win = Kephra::App::Window::_ref();
	return if not defined $nr or $nr < 0 or $nr > @fields or not $win or not defined $msg;
	$win->SetStatusText($msg, $nr);
}
sub index_from_mouse_pos {
	my $x_pos = shift;
	for (0 .. $#abs_border_x) {
		return $_ if $width{ $fields[$_] } == -1;
		return $_ if $x_pos <= $abs_border_x[$_];
	}
}
sub create {
	# $^O eq 'linux'
	my $win = Kephra::App::Window::_ref();
	$win->CreateStatusBar(1);
	my $bar = $win->GetStatusBar;

	my $statusbar_def = Kephra::Config::File::load_from_node_data( _config() );
	unless ($statusbar_def) {
		$statusbar_def = Kephra::Config::Default::toolbars()->{statusbar};
	}

	for my $nr (0 .. $#$statusbar_def) {
		my @item = split / /, $statusbar_def->[$nr];
		if ($item[0] eq 'textpanel' and defined $item[1]) {
			$index{$item[1]} = $nr;
			$width{$item[1]} = defined $item[2] ? $item[2] : 50;
		}
	}
	$fields[ $index{$_} ] = $_ for keys %index;
	$abs_border_x[0] = $width{ $fields[0] };
	$abs_border_x[$_] = $abs_border_x[$_-1] + $width{ $fields[$_] } + 2
		for 1 .. $#fields;

	my $length = scalar keys %index;
	$bar->SetFieldsCount( $length );
	my @field_width;
	$field_width[$_] = $width{ $fields[$_] } for 0 .. $length - 1;
	$bar->SetStatusWidths( @field_width );
	$win->SetStatusBarPane( $index{message} );

	Wx::Event::EVT_LEFT_DOWN ( $bar, \&left_click);
	Wx::Event::EVT_RIGHT_DOWN( $bar, \&right_click);

	Kephra::EventTable::add_call
		('caret.move',       'caret_status', \&caret_pos_info,   'status_bar');
	Kephra::EventTable::add_call
		('document.text.change', 'info_msg', \&refresh_info_msg, 'status_bar');
	Kephra::EventTable::add_call
		('editpanel.focus',      'info_msg', \&refresh_info_msg, 'status_bar');

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
	my ( $bar, $event ) = @_;
	my $x = $event->GetX;
	my $index = index_from_mouse_pos( $x );
	my $cell_start = $bar->GetFieldRect($index)->GetTopLeft;
	$x = $cell_start->x unless $width{ _item($index) } == -1;
	my $y = $cell_start->y; 
	my $field = _item( $index );
	my $menu = \&Kephra::App::ContextMenu::get;
	if    ($field eq 'syntaxmode'){$bar->PopupMenu( &$menu('status_syntaxmode'),$x,$y)}
	elsif ($field eq 'tab')       {$bar->PopupMenu( &$menu('status_tab'),       $x,$y)}
	elsif ($field eq 'EOL')       {$bar->PopupMenu( &$menu('status_eol'),       $x,$y)}
	elsif ($field eq 'message')   {$bar->PopupMenu( &$menu('status_info'),      $x,$y)}
}


sub left_click {
	return unless get_interactive();
	my ( $bar,    $event )  = @_;
	my $field = _item( index_from_mouse_pos( $event->GetX ) );
	if    ($field eq 'syntaxmode') {Kephra::Document::SyntaxMode::switch_auto()}
	elsif ($field eq 'tab')        {Kephra::Document::Property::switch_tab_mode()}
	elsif ($field eq 'EOL')        {Kephra::App::EditPanel::switch_EOL_visibility()}
	elsif ($field eq 'message')    {next_file_info(); }
}

sub get_interactive { _config()->{interactive} }
sub get_contextmenu_visibility { &get_interactive }
sub switch_contextmenu_visibility { _config()->{interactive} ^= 1 }


sub refresh_cursor {
	caret_pos_info();
	refresh_info_msg();
}

sub refresh_all_cells {
	refresh_cursor();
	style_info();
	codepage_info();
	tab_info();
	EOL_info();
	info_msg();
}

sub caret_pos_info {
	my $ep     = Kephra::App::EditPanel::_ref();
	my $pos    = $ep->GetCurrentPos;
	my $line   = $ep->LineFromPosition($pos) + 1;
	my $lpos   = $ep->GetColumn($pos) + 1;
	my $value;

	# caret pos display
	if ( $line > 9999  or $lpos > 9999 ) 
	     { _set_text(" $line : $lpos", $index{cursor} ) }
	else { _set_text("  $line : $lpos", $index{cursor} ) }

	# selection or  pos % display
	my ( $sel_beg, $sel_end ) = $ep->GetSelection;
	unless ( Kephra::Document::Data::attr('text_selected') ) {
		my $chars = $ep->GetLength;
		if ($chars) {
			my $value = int 100 * $pos / $chars + .5;
			$value = ' ' . $value if $value < 10;
			$value = ' ' . $value . ' ' if $value < 100;
			_set_text( "    $value%", $index{selection} );
		} else { _set_text( "    100%", $index{selection} ) }
	} else {
		if ( $ep->SelectionIsRectangle ) {
			my $x = abs int $ep->GetColumn($sel_beg) - $ep->GetColumn($sel_end);
			my $lines = 1 + abs int $ep->LineFromPosition($sel_beg)
				- $ep->LineFromPosition($sel_end);
			my $chars = $x * $lines;
			$lines = ' ' . $lines if $lines < 100;
			if ($lines < 10000) { $value = "$lines : $chars" }
			else                { $value = "$lines:$chars" }
			_set_text( $value, $index{selection} );
		} else {
			my $lines = 1 + $ep->LineFromPosition($sel_end)
						  - $ep->LineFromPosition($sel_beg);
			my $chars = $sel_end - $sel_beg - 
				($lines - 1) * Kephra::Document::Data::get_attribute('EOL_length');
			$lines = ' ' . $lines if $lines < 100;
			if ($lines < 10000) { $value = "$lines : $chars" }
			else                { $value = "$lines:$chars" }
			_set_text( $value, $index{selection});
		}
	}
}

sub style_info {
	my $style = shift;
	$style = Kephra::Document::Data::attr('syntaxmode') unless defined $style;
	$style = Kephra::Config::Localisation::strings()->{dialog}{general}{none}
		unless defined $style;
	_set_text( ' ' . $style, $index{syntaxmode} );
}
sub codepage_info {
	my $codepage = Kephra::Document::Data::attr('codepage');
	_set_text( ' ' . $codepage, $index{codepage} );
}
sub tab_info {
	my $mode  = Kephra::App::EditPanel::_ref()->GetUseTabs || 0;
	my $msg   = $mode ? ' HT' : ' ST';
	_set_text( $msg, $index{tab} );
}

sub EOL_info {
	my ( $mode, $msg ) = shift;
	$mode = Kephra::Document::Data::get_attribute('EOL') if !$mode;
	if ( !$mode or $mode eq 'none' or $mode eq 'no' )  {
		$msg = Kephra::Config::Localisation::strings()->{dialog}{general}{none};
	}
	elsif ( $mode eq 'cr'    or $mode eq 'mac' ) { $msg = " Mac" }
	elsif ( $mode eq 'lf'    or $mode eq 'lin' ) { $msg = "Linux" }
	elsif ( $mode eq 'cr+lf' or $mode eq 'win' ) { $msg = " Win" }
	_set_text( $msg, $index{EOL} );
}
#
# info messages
#
sub status_msg { info_msg(@_) }
sub info_msg   {
	my $msg;
	$msg .= $_ for @_;
	_set_text( $msg, $index{message} );
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
	_set_text( $msg, $index{message} );
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
		my $file = Kephra::Document::Data::get_file_path();
		if ($file) {
			my @time = localtime( $^T - ( -M $file ) * 86300 );
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
