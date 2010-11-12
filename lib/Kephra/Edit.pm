package Kephra::Edit;
our $VERSION = '0.41';

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

sub _selection_left_to_right {
	my $ep = shift || _ep_ref();
	my ($start, $end) = $ep->GetSelection;
	my $pos = $ep->GetCurrentPos;
	return -1 if $start == $end;
	return $start == $pos ? 0 : 1;
}
sub can_paste   { _ep_ref()->CanPaste }
sub can_copy    { Kephra::Document::Data::attr('text_selected') }
#
# simple textedit
#
sub cut         { _ep_ref()->Cut }
sub copy        {
	my $ep = _ep_ref();
	$ep->Copy;
	$ep->SelectionIsRectangle()
		? Kephra::Document::Data::set_value('copied_rect_selection',get_clipboard_text())
		: Kephra::Document::Data::set_value('copied_rect_selection','');
}
sub paste       {
	my $lch = Kephra::Document::Data::get_value('copied_rect_selection');
	my $cb = get_clipboard_text();
	(defined $lch and $lch eq $cb) ? paste_rectangular($cb) :  _ep_ref()->Paste;
}
sub paste_rectangular {
	my $text = shift || get_clipboard_text();
	my $ep = shift || _ep_ref();
	my $dragpos = shift;
	my $droppos = shift;
	# all additional parameters have to be provided or no one
	return -1 if defined $dragpos and not defined $droppos;

	my @lines = split( /[\r\n]+/, $text);
	$droppos = $ep->GetCurrentPos unless defined $dragpos;
	my $linenr = $ep->LineFromPosition( $droppos );
	my $colnr = $ep->GetColumn($droppos );

	if (defined $dragpos){
		# calculate real drop position if dragged foreward
		# because selection is cut out before inserted and this changed droppos
		if ($dragpos <= $droppos){
			my $selwidth = length $lines[0];
			my $dnddelta = $linenr - $ep->LineFromPosition( $dragpos );
			my $max = scalar @lines;

			#$dnddelta = $max < $dnddelta ? $max : $dnddelta;
			#$dnddelta *= $selwidth;
			#$droppos -= $dnddelta;
			#print "$dragpos ---$droppos\n";
		}
	}

	$ep->BeginUndoAction;
	$ep->ReplaceSelection(''),$ep->SetCurrentPos($droppos) if defined $dragpos;

	my $insertpos;
	for my $line (@lines){
		$insertpos = $ep->PositionFromLine($linenr) + $colnr;
		$insertpos += $colnr - $ep->GetColumn( $insertpos ) ;
		$insertpos = $ep->GetLineEndPosition($linenr)
			if $ep->LineFromPosition( $insertpos ) > $linenr;
		$ep->InsertText( $insertpos, $line);
		$linenr++;
	}
	$ep->EndUndoAction;
}
sub replace     {
	my $ep = _ep_ref();
	my $text = get_clipboard_text();
	copy();
	_ep_ref()->ReplaceSelection($text);
}

sub clear       { _ep_ref()->Clear }
sub get_clipboard_text {
	my $cboard = &Wx::wxTheClipboard;
	my $text;
	$cboard->Open;
	if ( $cboard->IsSupported( &Wx::wxDF_TEXT ) ) {
		my $data = Wx::TextDataObject->new;
		my $ok = $cboard->GetData( $data );
		if ( $ok ) {
			$text = $data->GetText;
		} else {
			# todo: error handling
		}
	}
	$cboard->Close;
	return defined $text ? $text : -1;
}

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
sub move_target {
	my $linedelta = shift;
	return unless defined $linedelta;
	my $ep = shift || _ep_ref(); 
	my $targetstart = $ep->GetTargetStart();
	my $targettext = $ep->GetTextRange($targetstart, $ep->GetTargetEnd());
	$ep->BeginUndoAction;
	$ep->ReplaceTarget('');
	$ep->InsertText($targetstart+$linedelta, $targettext);
	$ep->EndUndoAction;
}
sub move_selection {}
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

sub move_lines {
	my $linedelta = shift;
	return unless defined $linedelta;
	my $ep = shift || _ep_ref();

	my ( $selbegin, $selend) = $ep->GetSelection();
	my $sellength = $selend - $selbegin;
	my $selstartline = $ep->LineFromPosition($selbegin);
	my $targetstart = $ep->GetTargetStart();
	my $targetend = $ep->GetTargetEnd();
	my $blockbegin = $ep->PositionFromLine($selstartline);
	my $blockend = $ep->PositionFromLine( $ep->LineFromPosition($selend)+1 );
	my $selcolumn = $selbegin - $blockbegin;

	# endmode is taken when last line on start or end of operation has no EOL
	# then i take the the EOL char from the line before instead and have to
	# insert in a pos before to keep consistent
	my $endmode;
	if ($blockend == $ep->GetLength()
	or  $ep->LineFromPosition($selend) + $linedelta >= $ep->GetLineCount()-1 ) {
		$blockbegin = $ep->GetLineEndPosition($selstartline-1);
		$blockend = $ep->GetLineEndPosition( $ep->LineFromPosition($selend) );
		$endmode = 1;
	}
	$selstartline += $linedelta;
	my $blocktext = $ep->GetTextRange($blockbegin, $blockend);
	$ep->BeginUndoAction;
	$ep->SetTargetStart( $blockbegin );
	$ep->SetTargetEnd( $blockend );
	$ep->ReplaceTarget('');
	$selstartline = 0 if $selstartline < 0;
	$selstartline = $ep->GetLineCount() if $selstartline > $ep->GetLineCount();
	my $target = $endmode
		? $ep->GetLineEndPosition($selstartline-1)
		: $ep->PositionFromLine($selstartline);
	$ep->InsertText($target, $blocktext);
	$selbegin = $ep->PositionFromLine($selstartline) + $selcolumn;
	$ep->SetSelection($selbegin, $selbegin + $sellength);
	$ep->SetTargetStart($targetstart );
	$ep->SetTargetEnd( $targetend );
	$ep->EndUndoAction;
}

sub selection_move_left {
	my $ep = _ep_ref();
	my ($selbegin, $selend) = $ep->GetSelection();
	if ( $selbegin == $selend
	or $ep->LineFromPosition( $selbegin ) != $ep->LineFromPosition( $selend ) ) {
		Kephra::Edit::Format::dedent_tab();
	} else {
		if ( $selbegin > 0 ) {
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
}

sub selection_move_right{
	my $ep = _ep_ref();
	my ($selbegin, $selend) = $ep->GetSelection();
	if ( $selbegin == $selend
	or $ep->LineFromPosition( $selbegin ) != $ep->LineFromPosition( $selend ) ) {
		Kephra::Edit::Format::indent_tab();
	} else {
		if ( $selend < $ep->GetTextLength ) {
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
}

sub selection_move_up   {
	my $ep = shift || _ep_ref();
	my ($selbegin, $selend) = $ep->GetSelection();
	my $firstline = $ep->LineFromPosition( $selbegin );
	my $lastline = $ep->LineFromPosition( $selend );

	if ( $selbegin != $selend and $firstline == $lastline) {
	} 
	else { move_lines( -1, $ep ) }
}

sub selection_move_down {
	my $ep = shift || _ep_ref();
	my ($selbegin, $selend) = $ep->GetSelection();
	my $firstline = $ep->LineFromPosition( $selbegin );
	my $lastline = $ep->LineFromPosition( $selend );

	if ($selbegin != $selend and $firstline == $lastline) {
	}
	else { move_lines( 1, $ep ) }
}

sub selection_move_page_up   {
	my $ep = shift || _ep_ref();
	my ($selbegin, $selend) = $ep->GetSelection();
	my $firstline = $ep->LineFromPosition( $selbegin );
	my $lastline = $ep->LineFromPosition( $selend );
	my $linedelta = $ep->LinesOnScreen;

	if ($selbegin != $selend and $firstline == $lastline) {
	} 
	else { move_lines( -$linedelta, $ep ) }
}

sub selection_move_page_down {
	my $ep = shift || _ep_ref();
	my ($selbegin, $selend) = $ep->GetSelection();
	my $firstline = $ep->LineFromPosition( $selbegin );
	my $lastline = $ep->LineFromPosition( $selend );
	my $linedelta = $ep->LinesOnScreen;

	if ($selbegin != $selend and $firstline == $lastline) {
	} 
	else { move_lines( $linedelta, $ep ) }
}

#
sub insert {
	my ($text, $pos) = @_;
	return unless $text;
	my $ep = _ep_ref();
	$pos = $ep->GetCurrentPos unless defined $pos;
	$ep->InsertText($pos, $text);
	$pos += length $text;
	$ep->SetSelection($pos, $pos);
}
sub insert_text   { insert(@_) }
sub insert_at_pos { insert(@_) }
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
1;

=head1 NAME

Kephra::Edit - basic edit menu calls and internals for editing

=head1 DESCRIPTION

=cut