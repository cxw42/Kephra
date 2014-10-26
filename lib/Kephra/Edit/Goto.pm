package Kephra::Edit::Goto;
use strict;
use warnings;

our $VERSION = '0.04';

# editpanel navigation

use Wx qw( wxCANCEL wxSTC_CMD_PARAUP wxSTC_CMD_PARADOWN wxSTC_FIND_REGEXP);

sub line_nr {
	my $line = Kephra::Dialog::get_number( Kephra::App::Window::_ref(),
		$Kephra::localisation{'dialog'}{'edit'}{'goto_line_input'},
		$Kephra::localisation{'dialog'}{'edit'}{'goto_line_headline'},
		Kephra::App::EditPanel::_ref()->GetCurrentLine
	);
	Kephra::Edit::_goto_pos( Kephra::App::EditPanel::_ref->PositionFromLine($line - 1) )
		unless $line == wxCANCEL;
}

sub last_edit {
	Kephra::Edit::_goto_pos($Kephra::document{'current'}{'edit_pos'})
		if defined $Kephra::document{'current'}{'edit_pos'};
}

#########################
# block navigation
#########################
sub prev_block{ Kephra::App::EditPanel::_ref()->CmdKeyExecute(wxSTC_CMD_PARAUP) }
sub next_block{ Kephra::App::EditPanel::_ref()->CmdKeyExecute(wxSTC_CMD_PARADOWN)}

#########################
# brace navigation
#########################
sub prev_brace{
	my $ep  = Kephra::App::EditPanel::_ref();
	my $pos = $ep->GetCurrentPos;
	$ep->GotoPos($pos - 1) if $ep->BraceMatch($pos) > -1;
	$ep->GotoPos($pos - 2) if $ep->BraceMatch($pos - 1) > -1;
	$ep->SearchAnchor();
	my $newpos = $ep->SearchPrev(wxSTC_FIND_REGEXP, '[{}()\[\]]');
	$newpos++ if $ep->BraceMatch($newpos) > $newpos;
	$newpos > -1 ? $ep->GotoPos($newpos) : $ep->GotoPos($pos);
}

sub next_brace{
	my $ep  = Kephra::App::EditPanel::_ref();
	my $pos = $ep->GetCurrentPos;
	$ep->GotoPos($pos + 1);
	$ep->SearchAnchor();
	my $newpos = $ep->SearchNext(wxSTC_FIND_REGEXP, '[{}()\[\]]');
	$newpos++ if $ep->BraceMatch($newpos) > $newpos;
	$newpos > -1 ? $ep->GotoPos($newpos) : $ep->GotoPos($pos);
}

sub prev_related_brace{
	my $ep  = Kephra::App::EditPanel::_ref();
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
	my $ep  = Kephra::App::EditPanel::_ref();
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
