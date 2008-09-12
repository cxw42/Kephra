package Kephra::Edit;
our $VERSION = '0.31';

use strict;
use warnings;


# edit menu basic calls and internals for editing

use Wx qw(:stc);    #Kephra::Dialog::msg_box(undef,'',"");
use Wx qw(
	wxSTC_CMD_NEWLINE wxSTC_CMD_LINECUT wxSTC_CMD_LINEDELETE wxSTC_CMD_DELLINELEFT
	wxSTC_CMD_DELLINERIGHT wxSTC_CMD_UPPERCASE wxSTC_CMD_LOWERCASE
	wxSTC_CMD_LINETRANSPOSE wxSTC_CMD_LINECOPY wxSTC_CMD_WORDLEFT
	wxSTC_CMD_WORDRIGHT wxSTC_FIND_WORDSTART wxSTC_CMD_LINEEND
	wxSTC_CMD_DELETEBACK wxSTC_CMD_PASTE
	wxSTC_MARK_CIRCLE wxSTC_MARK_ARROW wxSTC_MARK_MINUS
	wxCANCEL);

#
# internal helper function
#
sub _get_panel { Kephra::App::EditPanel::_ref() }
sub _keep_focus{ Wx::Window::SetFocus( _get_panel() ) }

sub _let_caret_visible {
	my $ep = _get_panel();
	my ($selstart, $selend) = $ep->GetSelection;
	my $los = $ep->LinesOnScreen;
	if ( $selstart == $selend ) {
		$ep->ScrollToLine($ep->GetCurrentLine - ( $los / 2 ))
			unless $ep->GetCaretLineVisible;
	} else {
		my $startline = $ep->LineFromPosition($selstart);
		my $endline = $ep->LineFromPosition($selend);
		$ep->ScrollToLine( $startline - (($los - $endline - $startline) / 2) )
			unless $ep->GetLineVisible($startline)
			and $ep->GetLineVisible($endline);
	}
	$ep->EnsureCaretVisible;
}

sub _center_caret{
 my $ep = _get_panel();
	$ep->ScrollToLine($ep->GetCurrentLine - ( $ep->LinesOnScreen / 2 ));
	$ep->EnsureCaretVisible;
}

#Kephra::App::EditPanel::_get()->GotoPos(shift);
sub _goto_pos {
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

sub _save_positions {
	my $ep = _get_panel();
	my %pos;
	$pos{document}  = &Kephra::Document::_get_current_nr;
	$pos{pos}       = $ep->GetCurrentPos;
	$pos{line}      = $ep->GetCurrentLine;
	$pos{col}       = $ep->GetColumn( $pos{pos} );
	$pos{sel_begin} = $ep->GetSelectionStart;
	$pos{sel_end}   = $ep->GetSelectionEnd;
	push @{ $Kephra::temp{edit}{caret}{positions} }, \%pos;
}

sub _restore_positions {
	my $ep = _get_panel();
	my %pos      = %{ pop @{ $Kephra::temp{edit}{caret}{positions} } };
	if (%pos) {
		Kephra::Document::Change::to_number( $pos{document} )
			if $pos{document} != &Kephra::Document::_get_current_nr;
		$ep->SetCurrentPos( $pos{pos} );
		$ep->GotoLine( $pos{line} ) if $ep->GetCurrentLine != $pos{line};
		if ( $ep->GetColumn( $ep->GetCurrentPos ) == $pos{col} ) {
			$ep->SetSelection( $pos{sel_begin}, $pos{sel_end} );
		} else {
			my $npos = $ep->PositionFromLine( $pos{line} ) + $pos{col};
			my $max = $ep->GetLineEndPosition( $pos{line} );
			$npos = $max if $npos > $max;
			$ep->SetCurrentPos($npos);
			$ep->SetSelection( $npos, $npos );
		}
	}
	&_let_caret_visible;
}

sub _select_all_if_none {
	my $ep = _get_panel();
	my ($start, $end) = $ep->GetSelection;
	if ( $start == $end ) {
		$ep->SelectAll;
		$start = $ep->GetSelectionStart;
		$end   = $ep->GetSelectionEnd;
	}
	return $ep->GetTextRange( $start, $end );
}

sub can_paste { _get_panel()->CanPaste }
sub can_copy  { $Kephra::temp{current_doc}{text_selected} }

# simple textedit
sub cut       { _get_panel()->Cut }
sub copy      { _get_panel()->Copy }
sub paste     { _get_panel()->Paste }

sub replace {
	my $ep = _get_panel();
	my $length = ( $ep->GetSelectionEnd - $ep->GetSelectionStart );
	$ep->BeginUndoAction;
	$ep->SetSelectionEnd( $ep->GetSelectionStart );
	$ep->Paste;
	$ep->SetSelectionEnd( $ep->GetSelectionStart + $length );
	$ep->Cut;
	$ep->EndUndoAction;
}

sub clear { _get_panel()->Clear; }

sub del_back_tab{
	my $ep = _get_panel();
	my $pos = $ep->GetCurrentPos();
	my $tab_size = $Kephra::document{current}{tab_size};
	my $deltaspace = $ep->GetColumn($pos--) % $tab_size;
	$deltaspace = $tab_size unless $deltaspace;
	do { $ep->CmdKeyExecute(wxSTC_CMD_DELETEBACK) }
	while $ep->GetCharAt(--$pos) == 32 and --$deltaspace;
}

######################
# Edit Selection
######################

sub selection_move {
	my ( $ep, $linedelta ) = @_;
	my $text = $ep->GetSelectedText();

	$ep->BeginUndoAction;
	$ep->ReplaceSelection("");
	my $targetline = $ep->GetCurrentLine + $linedelta;
	my $lastline   = $ep->LineFromPosition(
		$ep->PositionFromLine( $ep->GetLineCount ) );
	$targetline = 0         if ( $targetline < 0 );
	$targetline = $lastline if ( $targetline > $lastline );
	my ( $oldpos, $oldline ) = ( $ep->GetCurrentPos, $ep->GetCurrentLine );
	my ( $posinline, $newpos)= ( $oldpos - $ep->PositionFromLine($oldline), 0 );

	if ($ep->GetLineEndPosition($targetline) - $ep->PositionFromLine($targetline)
		  < $posinline ) {
		$newpos = $ep->GetLineEndPosition($targetline);
	} else { $newpos = $ep->PositionFromLine($targetline) + $posinline }

	$ep->SetCurrentPos($newpos);
	$ep->InsertText( $newpos, $text );
	$ep->SetSelection( $newpos, $newpos + length($text) );
	$ep->EndUndoAction;
	&_let_caret_visible;
}

sub selection_move_left {
	my $ep = _get_panel();
	if ( $ep->GetSelectionStart > 0 ) {
		my $text = $ep->GetSelectedText();
		my $eoll = $Kephra::temp{current_doc}{EOL_length};
		$ep->BeginUndoAction;
		$ep->ReplaceSelection("");
		my $pos = $ep->GetCurrentPos;
		if ( $ep->GetColumn($pos) ) { $pos -= 1 }
		else                        { $pos -= $eoll }
		$ep->SetCurrentPos($pos);
		$ep->InsertText( $pos, $text );
		$ep->SetSelection( $pos, $pos + length($text) );
		$ep->EndUndoAction;
	}
}

sub selection_move_right {
	my $ep = _get_panel();
	if ( $ep->GetSelectionEnd < $ep->GetTextLength ) {
		my $text = $ep->GetSelectedText;
		my $eoll = $Kephra::temp{current_doc}{EOL_length};
		$ep->BeginUndoAction;
		$ep->ReplaceSelection("");
		my $pos  = $ep->GetCurrentPos;
		if ( $ep->GetColumn( $pos + $eoll ) ) { $pos += 1 }
		else                                  { $pos += $eoll }
		$ep->SetCurrentPos( $pos);
		$ep->InsertText( $pos, $text);
		$ep->SetSelection( $pos, $pos + length($text) );
		$ep->EndUndoAction;
	}
}

sub selection_move_up {
	my $ep = _get_panel();
	if ( $ep->LineFromPosition( $ep->GetSelectionStart ) > 0 ) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			$ep->CmdKeyExecute( wxSTC_CMD_LINETRANSPOSE );
			$ep->GotoLine( $ep->GetCurrentLine - 1 );
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, -1 );
		}
	}
}

sub selection_move_down {
	my $ep = _get_panel();
	if ($ep->LineFromPosition( $ep->GetSelectionEnd ) < $ep->GetLineCount - 1) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			$ep->GotoLine( $ep->GetCurrentLine + 1 );
			$ep->CmdKeyExecute(wxSTC_CMD_LINETRANSPOSE);
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, 1 );
		}
	}
}

sub selection_move_page_up {
	my $ep  = _get_panel();
	my $linedelta = $ep->LinesOnScreen;
	if ( $ep->LineFromPosition( $ep->GetSelectionStart ) > 0 ) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			my $targetline = $ep->GetCurrentLine - $linedelta;
			$targetline = 0 if $targetline < 0;
			for my $i (reverse $targetline + 1 .. $ep->GetCurrentLine ) {
				$ep->GotoLine($i);
				$ep->CmdKeyExecute(wxSTC_CMD_LINETRANSPOSE);
			}
			$ep->GotoLine( $ep->GetCurrentLine - 1 );
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, -$linedelta );
		}
	}
}

sub selection_move_page_down {
	my $ep  = _get_panel();
	my $linedelta = $ep->LinesOnScreen;
	if ($ep->LineFromPosition( $ep->GetSelectionEnd ) < $ep->GetLineCount - 1) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			my $targetline = $ep->GetCurrentLine + $linedelta;
			my $lastline   = $ep->LineFromPosition(
				$ep->PositionFromLine( $ep->GetLineCount ) );
			$targetline = $lastline if ( $targetline > $lastline );
			for my $i ($ep->GetCurrentLine + 1 .. $targetline) {
				$ep->GotoLine($i);
				$ep->CmdKeyExecute(wxSTC_CMD_LINETRANSPOSE);
			}
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, $linedelta );
		}
	}
}

######################

sub insert_text {
	my ($text, $pos) = @_;
	return unless $text;
	my $ep = _get_panel();
	if (defined $pos) { $ep->InsertText( $pos, $text) }
	else              { $ep->AddText( $text ) }
}

sub insert_at_pos {
	my ($text, $pos) = @_;
	_get_panel()->InsertText( $pos, $text);
}

######################
# Edit Line
######################

sub cut_current_line { _get_panel()->CmdKeyExecute(wxSTC_CMD_LINECUT) }
sub copy_current_line{ _get_panel()->CmdKeyExecute(wxSTC_CMD_LINECOPY)}
sub double_current_line {
	my $ep = _get_panel();
	my $pos = $ep->GetCurrentPos;
	$ep->BeginUndoAction;
	$ep->CmdKeyExecute(wxSTC_CMD_LINECOPY);
	$ep->CmdKeyExecute(wxSTC_CMD_PASTE);
	$ep->GotoPos($pos);
	$ep->EndUndoAction;
}

sub replace_current_line {
	my $ep   = _get_panel();
	my $line = $ep->GetCurrentLine;
	$ep->BeginUndoAction;
	$ep->GotoLine($line);
	$ep->Paste;
	$ep->SetSelection( $ep->GetSelectionEnd,
		$ep->GetLineEndPosition( $ep->GetCurrentLine ) );
	$ep->Cut;
	$ep->GotoLine($line);
	$ep->EndUndoAction;
}

sub del_current_line{_get_panel()->CmdKeyExecute(wxSTC_CMD_LINEDELETE)}
sub del_line_left {_get_panel()->CmdKeyExecute(wxSTC_CMD_DELLINELEFT) }
sub del_line_right{_get_panel()->CmdKeyExecute(wxSTC_CMD_DELLINERIGHT)}

#
sub eval_newline_sub{
}

##########################

1;
