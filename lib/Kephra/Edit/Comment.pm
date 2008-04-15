package Kephra::Edit::Comment;
$VERSION = '0.07';

use strict;

# Comment
sub add_block {
	my $csymbol = shift;
	my $ep = &Kephra::App::EditPanel::_ref;
	my ( $lb, $lie );

	#lb = LineBegin; lie = LineIndentEnd
	$ep->BeginUndoAction;
	my $a = $ep->LineFromPosition( $ep->GetSelectionStart );
	my $b = $ep->LineFromPosition( $ep->GetSelectionEnd );
	for ( $a .. $b ) {
		$lb  = $ep->PositionFromLine($_);
		$lie = $ep->GetLineIndentPosition($_);
		$ep->SetTargetStart($lb);
		$ep->SetTargetEnd( $lie + length($csymbol) );
		$ep->InsertText($lie, $csymbol) if $ep->SearchInTarget($csymbol) == -1;
	}
	$ep->EndUndoAction;
}

sub remove_block {
	my $csymbol = shift;
	my $ep = &Kephra::App::EditPanel::_ref;
	my $lp;
	my $a = $ep->LineFromPosition( $ep->GetSelectionStart() );
	my $b = $ep->LineFromPosition( $ep->GetSelectionEnd() );
	$ep->BeginUndoAction;
	for ( $a .. $b ) {
		$lp = $ep->PositionFromLine($_);
		$ep->SetTargetStart($lp);
		$ep->SetTargetEnd( $ep->GetLineIndentPosition($_) + length($csymbol) );
		$ep->ReplaceTarget("") if $ep->SearchInTarget($csymbol) > -1;
	}
	$ep->SetSelectionStart( $ep->GetCurrentPos );
	$ep->EndUndoAction;
}

sub toggle_block {
	my $csymbol  = shift;
	my $ep = &Kephra::App::EditPanel::_ref;
	my ($lb, $lie);
	my $a = $ep->LineFromPosition( $ep->GetSelectionStart() );
	my $b = $ep->LineFromPosition( $ep->GetSelectionEnd() );
	$ep->BeginUndoAction;
	for ($a .. $b) {
		$lb  = $ep->PositionFromLine($_);
		$lie = $ep->GetLineIndentPosition($_);
		$ep->SetTargetStart($lb);
		$ep->SetTargetEnd( $lie + length($csymbol) );
		if ($ep->SearchInTarget($csymbol) == -1){$ep->InsertText($lie,$csymbol)}
		else                                    {$ep->ReplaceTarget("")}
	}
	$ep->EndUndoAction;
}

sub format_block {
	my $csymbol  = shift;
	my $ep = Kephra::App::EditPanel::_ref();
	my $lp;
	my $a = $ep->LineFromPosition( $ep->GetSelectionStart );
	my $b = $ep->LineFromPosition( $ep->GetSelectionEnd );
	$ep->BeginUndoAction;
	for ($b .. $a) {
		$lp = $ep->PositionFromLine($_);
	}
	$ep->EndUndoAction;
}

sub add_stream {
	my $ep = Kephra::App::EditPanel::_ref();
	my ( $openbrace, $closebrace ) = @_;
	my ( $startpos, $endpos ) = $ep->GetSelection;
	my ( $commentpos, $firstopos, $lastopos, $firstcpos, $lastcpos )
		= ( -1, $endpos, -1, $endpos, -1 );
	$ep->BeginUndoAction;
	$ep->SetTargetStart($startpos);
	$ep->SetTargetEnd($endpos);
	while ( ( $commentpos = $ep->SearchInTarget($openbrace) ) > -1 ) {
		$firstopos = $commentpos if $firstopos > $commentpos;
		$lastopos = $commentpos;
		$ep->SetSelectionStart($commentpos);
		$ep->SetSelectionEnd( $commentpos + length($openbrace) );
		$ep->ReplaceSelection("");
		$endpos -= length($openbrace);
		$ep->SetTargetStart($commentpos);
		$ep->SetTargetEnd($endpos);
	}
	$ep->SetTargetStart($startpos);
	$ep->SetTargetEnd($endpos);
	while ( ( $commentpos = $ep->SearchInTarget($closebrace) ) > -1 ) {
		$firstcpos = $commentpos if ( $firstcpos > $commentpos );
		$lastcpos = $commentpos;
		$ep->SetSelectionStart($commentpos);
		$ep->SetSelectionEnd( $commentpos + length($closebrace) );
		$ep->ReplaceSelection("");
		$endpos -= length($closebrace);
		$ep->SetTargetStart($commentpos);
		$ep->SetTargetEnd($endpos);
	}
	$ep->InsertText( $endpos,   $closebrace ) if $lastcpos == -1;
	$ep->InsertText( $startpos, $openbrace ) if $lastopos == -1;
	$ep->InsertText( $startpos, $openbrace ) if $firstopos < $firstcpos;
	$ep->InsertText( $endpos,   $closebrace ) if  $lastopos < $lastcpos;
	#$ep->InsertText($endpos, $closebrace);
	#$ep->InsertText($startpos, $openbrace);
	$ep->EndUndoAction;
}

sub remove_stream {    #o=openposition c=closeposition
	my ( $openbrace, $closebrace ) = @_;
	my $ep = Kephra::App::EditPanel::_ref();
	my ( $startpos, $endpos ) = $ep->GetSelection();
	my $firstopos = my $firstcpos =               $endpos;
	my $commentpos = my $lastopos = my $lastcpos = -1;
	if ( $startpos < $endpos ) {
		$ep->BeginUndoAction();
		$ep->SetTargetStart($startpos);
		$ep->SetTargetEnd($endpos);
		while ( ( $commentpos = $ep->SearchInTarget($openbrace) ) > -1 ) {
			$firstopos = $commentpos if ( $firstopos > $commentpos );
			$lastopos = $commentpos;
			$ep->SetSelectionStart($commentpos);
			$ep->SetSelectionEnd( $commentpos + length($openbrace) );
			$ep->ReplaceSelection("");
			$endpos -= length($openbrace);
			$ep->SetTargetStart($commentpos);
			$ep->SetTargetEnd($endpos);
		}
		$ep->SetTargetStart($startpos);
		$ep->SetTargetEnd($endpos);
		while ( ($commentpos = $ep->SearchInTarget($closebrace) ) > -1 ) {
			$firstcpos = $commentpos if ( $firstcpos > $commentpos );
			$lastcpos = $commentpos;
			$ep->SetSelectionStart($commentpos);
			$ep->SetSelectionEnd( $commentpos + length($closebrace) );
			$ep->ReplaceSelection("");
			$endpos -= length($closebrace);
			$ep->SetTargetStart($commentpos);
			$ep->SetTargetEnd($endpos);
		}
		if ( $firstopos > $firstcpos ) {
			$ep->InsertText( $startpos, $closebrace );
		}
		if ( $lastopos > $lastcpos ) {
			$ep->InsertText( $endpos, $openbrace );
		}
		if ( ( $lastopos == -1 ) && ( $lastcpos == -1 ) ) {
			$ep->InsertText( $startpos, $closebrace );
			$ep->InsertText( $endpos + length($closebrace), $openbrace );
		}
		$ep->EndUndoAction();
	}
}

sub add_script    { add_block   ('#') }
sub sub_script    { remove_block('#') }
sub toggle_script { toggle_block('#') }
sub format_script { format_block('#') }
sub add_xml       { add_stream   ( '<!--', '-->' ) }
sub sub_xml       { remove_stream( '<!--', '-->' ) }
sub add_c         { add_stream   ( '/*', '*/' ) }
sub sub_c         { remove_stream( '/*', '*/' ) }

1;
