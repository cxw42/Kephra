package Kephra::Edit::Goto;
our $VERSION = '0.06';

use strict;
use warnings;

# editpanel navigation

use Wx qw( wxCANCEL wxSTC_CMD_PARAUP wxSTC_CMD_PARADOWN wxSTC_FIND_REGEXP);

sub _get_panel { Kephra::App::EditPanel::_ref() }
sub _center_caret { Kephra::Edit::_center_caret() }


sub pos { position(@_) }
sub position {
	my $pos = shift;
	my $ep  = _get_panel();
	my $max = $ep->GetLength;
	my $fvl = $ep->GetFirstVisibleLine;
	my $visible = $ep->GetLineVisible( $ep->LineFromPosition($pos) );

	$pos = 0 unless $pos or $pos < 0;
	$pos = $max if $pos > $max;
	$ep->SetCurrentPos($pos);
	$ep->SetSelection ($pos, $pos);
	$ep->SearchAnchor;
	_center_caret();
	#$visible ? $ep->ScrollToLine($fvl) : _center_caret();
	$ep->EnsureCaretVisible;
	#_keep_focus();
}
sub next_visible_pos {
	my $ep  = _get_panel();
	my $line = $ep->GetCurrentLine();
	return if $ep->GetLineVisible($line);
	$line = $ep->GetFoldParent($line) until $ep->GetLineVisible($line);
	$ep->GotoLine($line);
}

sub line_nr {
	my $ep = _get_panel();
	my $l18n = Kephra::Config::Localisation::strings()->{dialog}{edit};
	my $line = Kephra::Dialog::get_number( 
		Kephra::App::Window::_ref(),
		$l18n->{goto_line_input}, $l18n->{goto_line_headline},
		$ep->GetCurrentLine + 1
	);
	position( $ep->PositionFromLine($line - 1) ) unless $line == wxCANCEL;
}

sub last_edit {
	position( $Kephra::document{current}{edit_pos} )
		if defined $Kephra::document{current}{edit_pos};
}

#
# block navigation
#
sub prev_block{ _get_panel()->CmdKeyExecute(wxSTC_CMD_PARAUP)   }
sub next_block{ _get_panel()->CmdKeyExecute(wxSTC_CMD_PARADOWN) }
#
# brace navigation
#
sub prev_brace{
	my $ep  = _get_panel();
	my $pos = $ep->GetCurrentPos;
	$ep->GotoPos($pos - 1) if $ep->BraceMatch($pos) > -1;
	$ep->GotoPos($pos - 2) if $ep->BraceMatch($pos - 1) > -1;
	$ep->SearchAnchor();
	my $newpos = $ep->SearchPrev(wxSTC_FIND_REGEXP, '[{}()\[\]]');
	$newpos++ if $ep->BraceMatch($newpos) > $newpos;
	$newpos > -1 ? $ep->GotoPos($newpos) : $ep->GotoPos($pos);
}

sub next_brace{
	my $ep  = _get_panel();
	my $pos = $ep->GetCurrentPos;
	$ep->GotoPos($pos + 1);
	$ep->SearchAnchor();
	my $newpos = $ep->SearchNext(wxSTC_FIND_REGEXP, '[{}()\[\]]');
	$newpos++ if $ep->BraceMatch($newpos) > $newpos;
	$newpos > -1 ? $ep->GotoPos($newpos) : $ep->GotoPos($pos);
}

sub prev_related_brace{
	my $ep  = _get_panel();
	my $pos = $ep->GetCurrentPos;
	my $matchpos = $ep->BraceMatch(--$pos);
	$matchpos = $ep->BraceMatch(++$pos) if $matchpos == -1;
	if ($matchpos == -1) { prev_brace() }
	else {
		if ($matchpos < $pos) { $ep->GotoPos($matchpos+1) }
		else{
			my $open_char = chr $ep->GetCharAt($pos);
			my $close_char = chr $ep->GetCharAt($matchpos);
			$ep->GotoPos($pos);
			$ep->SearchAnchor();
			my $next_open = $ep->SearchPrev(0, $open_char);
			$ep->GotoPos($pos);
			$ep->SearchAnchor();
			my $next_close = $ep->SearchPrev(0, $close_char);
			if ($next_open < $next_close) { $ep->GotoPos( $next_open + 1 ) }
			else                          { $ep->GotoPos( $next_close    ) }
		}
	}
}

sub next_related_brace{
	my $ep  = _get_panel();
	my $pos = $ep->GetCurrentPos;
	my $matchpos = $ep->BraceMatch($pos);
	$matchpos = $ep->BraceMatch(--$pos) if $matchpos == -1;
	if ($matchpos == -1) { next_brace() }
	else {
		if ($matchpos > $pos) { $ep->GotoPos($matchpos) }
		else{
			my $open_char = chr $ep->GetCharAt($matchpos);
			my $close_char = chr $ep->GetCharAt($pos);
			$ep->GotoPos($pos + 1);
			$ep->SearchAnchor();
			my $next_open = $ep->SearchNext(0, $open_char);
			$ep->GotoPos($pos + 1);
			$ep->SearchAnchor();
			my $next_close = $ep->SearchNext(0, $close_char);
			if ($next_open < $next_close) { $ep->GotoPos( $next_open + 1 ) }
			else                          { $ep->GotoPos( $next_close    ) }
		}
	}
}

1;
