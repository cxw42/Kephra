package Kephra::Edit::Format;
$VERSION = '0.23';

use strict;
use Wx qw(
	wxSTC_CMD_NEWLINE wxSTC_CMD_DELETEBACK wxSTC_CMD_LINEEND
	wxSTC_CMD_WORDLEFT wxSTC_CMD_WORDRIGHT
);

sub _get_panel { Kephra::App::EditPanel::_ref() }

# change indention width of selected text
sub _indent_selection {
	my $width = shift || 0;
	my $ep    = _get_panel();
	$ep->BeginUndoAction;
	$ep->SetLineIndentation( $_, $ep->GetLineIndentation($_) + $width ) 
		for $ep->LineFromPosition($ep->GetSelectionStart)
		 .. $ep->LineFromPosition($ep->GetSelectionEnd);
	$ep->EndUndoAction;
}

sub autoindent {
	my $ep   = _get_panel();
	my $line = $ep->GetCurrentLine;

	$ep->BeginUndoAction;
	$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);
	my $indent = $ep->GetLineIndentation( $line );
	$ep->SetLineIndentation( $line + 1, $indent);
	$ep->GotoPos( $ep->GetLineIndentPosition( $line + 1 ) );
	$ep->EndUndoAction;
}

sub blockindent_open {
	my $ep         = _get_panel();
	my $tabsize    = $Kephra::document{current}{tab_size};
	my $line       = $ep->GetCurrentLine;
	my $first_cpos = $ep->PositionFromLine($line)
		+ $ep->GetLineIndentation($line); # position of first char in line
	my $matchfirst = $ep->BraceMatch($first_cpos);

	$ep->BeginUndoAction;

	# dedent a "} else {" correct
	if ($ep->GetCharAt($first_cpos) == 125 and $matchfirst > -1) {
		$ep->SetLineIndentation( $line, $ep->GetLineIndentation(
				$ep->LineFromPosition($matchfirst) ) );
	}
	# grabbing
	my $bracepos   = $ep->GetCurrentPos - 1;
	my $leadindent = $ep->GetLineIndentation($line);
	my $matchbrace = $ep->BraceMatch( $bracepos );
	my $matchindent= $ep->GetLineIndentation($ep->LineFromPosition($matchbrace));

	# make newl line
	$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);

	# make new brace if there is missing one
	if ($Kephra::config{editpanel}{auto}{brace}{make} and
		($matchbrace == -1 or $ep->GetLineIndentation($line) != $matchindent )){
		$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);
		$ep->AddText('}');
		$ep->SetLineIndentation( $line + 2, $leadindent );
	}
	$ep->SetLineIndentation( $line + 1, $leadindent + $tabsize );
	$ep->GotoPos( $ep->GetLineIndentPosition( $line + 1 ) );

	$ep->EndUndoAction;
}

sub blockindent_close {
	my $ep = _get_panel();
	my $bracepos = shift;
	unless ($bracepos) {
		$bracepos = $ep->GetCurrentPos - 1;
		$bracepos-- while $ep->GetCharAt($bracepos) == 32;
	}

	$ep->BeginUndoAction;

	# 1 if it not textend, goto next line
	my $match = $ep->BraceMatch($bracepos);
	my $line  = $ep->GetCurrentLine;
	unless ($ep->GetLineIndentPosition($line)+1 == $ep->GetLineEndPosition($line)
		or  $ep->LineFromPosition($match) == $line ) {
		$ep->GotoPos($bracepos);
		$ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);
		$ep->GotoPos( $ep->GetCurrentPos + 1 );
		$line++;
	}

	# 2 wenn match dann korrigiere einrückung ansonst letzte - tabsize
	if ( $match > -1 ) {
		$ep->SetLineIndentation( $line,
			$ep->GetLineIndentation( $ep->LineFromPosition($match) ) );
	} else {
		$ep->SetLineIndentation( $line,
			$ep->GetLineIndentation( $line - 1 )
				- $Kephra::document{current}{tab_size} );
	}

	# make new line
	$Kephra::config{editpanel}{auto}{indent}
		? autoindent()
		: $ep->CmdKeyExecute(wxSTC_CMD_NEWLINE);

	# 3 lösche dubs wenn in nächster zeile nur spaces bis dup
	#if ( $Kephra::config{editpanel}{auto}{brace}{join} ) {
		#my $delbrace = $ep->PositionFromLine( $line + 2 )
			#+ $ep->GetLineIndentation( $line + 1 );
		#if ( $ep->GetCharAt($delbrace) == 125 ) {
			#$ep->SetTargetStart( $ep->GetCurrentPos );
			#$ep->SetTargetEnd( $delbrace + 1 );
			#$ep->ReplaceTarget('');
		#}
	#}

	$ep->EndUndoAction;
}

sub indent_space { _indent_selection( 1) }
sub dedent_space { _indent_selection(-1) }
sub indent_tab   { _indent_selection( $Kephra::document{current}{tab_size}) }
sub dedent_tab   { _indent_selection(-$Kephra::document{current}{tab_size}) }

#
sub align_indent {
	my $ep = _get_panel();
	my $firstline = $ep->LineFromPosition( $ep->GetSelectionStart );
	my $align = $ep->GetLineIndentation($firstline);
	$ep->BeginUndoAction();
	$ep->SetLineIndentation($_ ,$align)
		for $firstline + 1 .. $ep->LineFromPosition($ep->GetSelectionEnd);
	$ep->EndUndoAction();
}

# deleting trailing spaces on line ends
sub del_trailing_spaces {
	&Kephra::Edit::_save_positions;
	my $ep = _get_panel();
	my $text = Kephra::Edit::_select_all_if_none();
	$text =~ s/[ \t]+(\r|\n|\Z)/$1/g;
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
	Kephra::Edit::_restore_positions();
}

#
sub join_lines {
 my $ep = _get_panel();
 my $text = $ep->GetSelectedText();
	$text =~ s/[\r|\n]+/ /g; # delete end of line marker
	$ep->BeginUndoAction;
	$ep->ReplaceSelection($text);
	$ep->EndUndoAction;
}

sub blockformat{
	return unless Scalar::Util::looks_like_number($_[0]);
	my $width     = (int shift) + 1;
	my $ep        = _get_panel();
	my ($begin, $end) = $ep->GetSelection;
	my $bline     = $ep->LineFromPosition($begin);
	my $tmp_begin = $ep->PositionFromLine($bline);
	my $bspace    = ' ' x $ep->GetLineIndentation($bline);
	my $space     = $Kephra::config{editpanel}{auto}{indention} ? $bspace : '';
	chop $bspace;

	$ep->SetSelection($tmp_begin, $end);
	require Text::Wrap;
	$Text::Wrap::columns  = $width;
	$Text::Wrap::unexpand = $Kephra::document{current}{tab_use};
	$Text::Wrap::tabstop  = $Kephra::document{current}{tab_size};

	my $text = $ep->GetSelectedText;
	$text =~ s/[\r|\n]+/ /g;
	$ep->BeginUndoAction();
	$ep->ReplaceSelection( Text::Wrap::fill($bspace, $space, $text) );
	$ep->EndUndoAction();
}

sub blockformat_LLI{
	blockformat( $Kephra::config{editpanel}{indicator}{right_margin}{position} );
}

sub blockformat_custom{
	my $width = Kephra::Dialog::get_text( Kephra::App::Window::_get(),
			$Kephra::localisation{dialog}{edit}{wrap_width_input},
			$Kephra::localisation{dialog}{edit}{wrap_custom_headline}
	);
	blockformat( $width ) if defined $width;
}



# breaking too long lines into smaller one
sub line_break {
	return unless Scalar::Util::looks_like_number($_[0]);
	my $width        = (int shift) + 1;
	my $ep           = _get_panel();
	my ($begin, $end)= $ep->GetSelection;
	my $tmp_begin    = $ep->LineFromPosition( $ep->PositionFromLine($begin) );

	$ep->SetSelection($tmp_begin, $end);
	require Text::Wrap;
	$Text::Wrap::columns  = $width;
	$Text::Wrap::unexpand = $Kephra::document{current}{tab_use};
	$Text::Wrap::tabstop  = $Kephra::document{current}{tab_size};

	$ep->BeginUndoAction();
	$ep->ReplaceSelection( Text::Wrap::wrap('', '', $ep->GetSelectedText) );
	$ep->EndUndoAction();
}

sub linebreak_custom {
	my $l10n = $Kephra::localisation{dialog}{edit};
	my $width = Kephra::Dialog::get_text( Kephra::App::Window::_get(),
			$l10n->{wrap_width_input}, $l10n->{wrap_custom_headline} );
	line_break( $width ) if defined $width;
}

sub linebreak_LLI {
	line_break( $Kephra::config{editpanel}{indicator}{right_margin}{position} );
}

sub linebreak_window {
	my $app = Kephra::App::Window::_get();
	my $ep  = _get_panel();
	my ($width) = $app->GetSizeWH();
	my $pos = $ep->GetColumn($ep->PositionFromPointClose(100, 67));
	Kephra::Dialog::msg_box( $app, $pos, '' );
	#line_break($width);
}

1;
