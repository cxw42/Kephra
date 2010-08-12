package Kephra::Edit;
our $VERSION = '0.34';

use strict;
use warnings;
#
# internal helper function
#
sub _ep_ref { Kephra::App::EditPanel::_ref() }
sub _keep_focus{ Wx::Window::SetFocus( _ep_ref() ) }
sub _let_caret_visible {
	my $ep = _ep_ref();
	my ($selstart, $selend) = $ep->GetSelection;
	my $los = $ep->LinesOnScreen;
	if ( $selstart == $selend ) {
		$ep->ScrollToLine($ep->GetCurrentLine - ( $los / 2 ))
			unless $ep->GetLineVisible( $ep->GetCurrentLine() );
	} else {
		my $startline = $ep->LineFromPosition($selstart);
		my $endline = $ep->LineFromPosition($selend);
		$ep->ScrollToLine( $startline - (($los - $endline - $startline) / 2) )
			unless $ep->GetLineVisible($startline)
			and $ep->GetLineVisible($endline);
	}
	$ep->EnsureCaretVisible;
}

sub _center_caret {
	my $ep = _ep_ref();
	my $line = $ep->GetCurrentLine();
	$ep->ScrollToLine( $line - ( $ep->LinesOnScreen / 2 ));
	$ep->EnsureVisible($line);
	$ep->EnsureCaretVisible();
}

my @pos_stack;
sub _save_positions {
	my $ep = _ep_ref();
	my %pos;
	$pos{document}  = Kephra::Document::Data::current_nr();
	$pos{pos}       = $ep->GetCurrentPos;
	$pos{line}      = $ep->GetCurrentLine;
	$pos{col}       = $ep->GetColumn( $pos{pos} );
	$pos{sel_begin} = $ep->GetSelectionStart;
	$pos{sel_end}   = $ep->GetSelectionEnd;
	push @pos_stack, \%pos;
}

sub _restore_positions {
	my $ep = _ep_ref();
	my %pos = %{ pop @pos_stack };
	if (%pos) {
		Kephra::Document::Change::to_number( $pos{document} )
			if $pos{document} != Kephra::Document::Data::current_nr();
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
    my $ep = _ep_ref();
    my ($start, $end) = $ep->GetSelection;
    if ( $start == $end ) {
        $ep->SelectAll;
        ($start, $end) = $ep->GetSelection;
    }
    return $ep->GetTextRange( $start, $end );
}

sub can_paste   { _ep_ref()->CanPaste }
sub can_copy    { Kephra::Document::Data::attr('text_selected') }

# simple textedit
sub cut         { _ep_ref()->Cut }
sub copy        { _ep_ref()->Copy }
sub paste       { _ep_ref()->Paste }
sub replace     {
	my $ep = _ep_ref();
	my $length = ( $ep->GetSelectionEnd - $ep->GetSelectionStart );
	$ep->BeginUndoAction;
	$ep->SetSelectionEnd( $ep->GetSelectionStart );
	$ep->Paste;
	$ep->SetSelectionEnd( $ep->GetSelectionStart + $length );
	$ep->Cut;
	$ep->EndUndoAction;
}

sub clear       { _ep_ref()->Clear }

sub del_back_tab{
	my $ep = _ep_ref();
	my $pos = $ep->GetCurrentPos();
	my $tab_size = Kephra::Document::Data::attr('tab_size');
	my $deltaspace = $ep->GetColumn($pos--) % $tab_size;
	$deltaspace = $tab_size unless $deltaspace;
	do { $ep->CmdKeyExecute(&Wx::wxSTC_CMD_DELETEBACK) }
	while $ep->GetCharAt(--$pos) == 32 and --$deltaspace;
}

#
# Edit Selection
#
sub get_selection  { _ep_ref()->GetSelectedText() }
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
	my $ep = _ep_ref();
	if ( $ep->GetSelectionStart > 0 ) {
		my $text = $ep->GetSelectedText();
		my $eoll = Kephra::Document::Data::attr('EOL_length');;
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

sub selection_move_right{
	my $ep = _ep_ref();
	if ( $ep->GetSelectionEnd < $ep->GetTextLength ) {
		my $text = $ep->GetSelectedText;
		my $eoll = Kephra::Document::Data::attr('EOL_length');
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

sub selection_move_up   {
	my $ep = shift || _ep_ref();
	if ( $ep->LineFromPosition( $ep->GetSelectionStart ) > 0 ) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			my $line = $ep->GetCurrentLine;
			my $col = $ep->GetCurrentPos - $ep->PositionFromLine($line);
			$ep->BeginUndoAction;
			$ep->CmdKeyExecute( &Wx::wxSTC_CMD_LINETRANSPOSE );
			my $pos = $ep->PositionFromLine( $line - 1 ) + $col;
			$ep->SetCurrentPos( $pos );
			$ep->SetSelection( $pos, $pos );
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, -1 );
		}
	}
}

sub selection_move_down {
	my $ep = shift || _ep_ref();
	if ($ep->LineFromPosition( $ep->GetSelectionEnd ) < $ep->GetLineCount - 1) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			my $line = $ep->GetCurrentLine;
			my $col = $ep->GetCurrentPos() - $ep->PositionFromLine($line);
			$ep->BeginUndoAction;
			$ep->GotoLine( $line + 1 );
			$ep->CmdKeyExecute( &Wx::wxSTC_CMD_LINETRANSPOSE );
			my $pos = $ep->PositionFromLine($line + 1) + $col;
			$ep->SetCurrentPos( $pos );
			$ep->SetSelection( $pos, $pos );
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, 1 );
		}
	}
}

sub selection_move_page_up   {
	my $ep = _ep_ref();
	my $linedelta = $ep->LinesOnScreen;
	if ( $ep->LineFromPosition( $ep->GetSelectionStart ) > 0 ) {
		if ( $ep->GetSelectionStart == $ep->GetSelectionEnd ) {
			$ep->BeginUndoAction;
			my $targetline = $ep->GetCurrentLine - $linedelta;
			$targetline = 0 if $targetline < 0;
			for my $i (reverse $targetline + 1 .. $ep->GetCurrentLine ) {
				$ep->GotoLine($i);
				$ep->CmdKeyExecute(&Wx::wxSTC_CMD_LINETRANSPOSE);
			}
			$ep->GotoLine( $ep->GetCurrentLine - 1 );
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, -$linedelta );
		}
	}
}

sub selection_move_page_down {
	my $ep = _ep_ref();
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
				$ep->CmdKeyExecute(&Wx::wxSTC_CMD_LINETRANSPOSE);
			}
			$ep->EndUndoAction;
		} else {
			selection_move( $ep, $linedelta );
		}
	}
}

#
sub insert {
	my ($text, $pos) = @_;
	return unless $text;
	my $ep = _ep_ref();
	if (defined $pos) { $ep->InsertText( $pos, $text) }
	else              { $ep->AddText( $text ) }
}

sub insert_at_pos { _ep_ref()->InsertText( @_ ) }
#
# Edit Line
#
sub cut_current_line { _ep_ref()->CmdKeyExecute(&Wx::wxSTC_CMD_LINECUT) }
sub copy_current_line{ _ep_ref()->CmdKeyExecute(&Wx::wxSTC_CMD_LINECOPY)}
sub double_current_line {
	my $ep = _ep_ref();
	my $pos = $ep->GetCurrentPos;
	$ep->BeginUndoAction;
	$ep->CmdKeyExecute(&Wx::wxSTC_CMD_LINECOPY);
	$ep->CmdKeyExecute(&Wx::wxSTC_CMD_PASTE);
	$ep->GotoPos($pos);
	$ep->EndUndoAction;
}

sub replace_current_line {
	my $ep = _ep_ref();
	my $line = $ep->GetCurrentLine;
	$ep->BeginUndoAction;
	$ep->GotoLine($line);
	$ep->Paste;
	$ep->SetSelection( 
		$ep->GetSelectionEnd,
		$ep->GetLineEndPosition( $ep->GetCurrentLine )
	);
	$ep->Cut;
	$ep->GotoLine($line);
	$ep->EndUndoAction;
}

sub del_current_line{_ep_ref()->CmdKeyExecute(&Wx::wxSTC_CMD_LINEDELETE)}
sub del_line_left   {_ep_ref()->DelLineLeft() }
sub del_line_right  {_ep_ref()->DelLineRight()}

sub eval_newline_sub{}

#
# special edit functions
#
sub copy_surrounding_string { # Edit String (surrounding string encapsulated by "" or '')
	my $ep = _ep_ref();
	my $pos  = $ep->GetCurrentPos;
	my $line = $ep->GetCurrentLine;
	my $lpos = $ep->PositionFromLine($line);
	my $befor_text = $ep->GetTextRange($lpos, $pos);
	my $after_text = $ep->GetTextRange($pos+1, $ep->GetLineEndPosition($line));
	my $sq_start = rindex $befor_text, '\'';
	my $sq_stop  = index $after_text, '\'';
	my $dq_start = rindex $befor_text, '"';
	my $dq_stop  = index $after_text, '"';
	return if  ($sq_start == -1 or $sq_stop == -1) 
	       and ($dq_start == -1 or $dq_stop == -1);
	_save_positions();
	if ($sq_start > $dq_start){$ep->SetSelection($lpos+$sq_start+1, $pos+$sq_stop+1)}
	else                      {$ep->SetSelection($lpos+$dq_start+1, $pos+$dq_stop+1)}
	copy();
	_restore_positions();
}

sub insert_last_perl_var {
	my $ep = _ep_ref();
	my $lnr = $ep->GetCurrentLine;
	return unless $lnr;
	my $pos  = $ep->GetCurrentPos;
	my $line = $ep->GetLine($lnr - 1);
	my $result = $line =~ /([\$@%]\w+)[ -=\(\r\n]/;
	return unless $1;
	$ep->InsertText( $pos, $1);
	$ep->GotoPos($pos + length $1);
}
1;

=head1 NAME

Kephra::Edit - basic edit menu calls and internals for editing

=head1 DESCRIPTION

=cut