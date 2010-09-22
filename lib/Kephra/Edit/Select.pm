package Kephra::Edit::Select;
our $VERSION = '0.06';

use strict;
use warnings;
sub _ep_ref { Kephra::App::EditPanel::is( shift ) || Kephra::App::EditPanel::_ref() }

sub to_block_begin{ _ep_ref()->CmdKeyExecute(&Wx::wxSTC_CMD_PARAUPEXTEND)   }
sub to_block_end  { _ep_ref()->CmdKeyExecute(&Wx::wxSTC_CMD_PARADOWNEXTEND) }

sub clear {
	my $ep = _ep_ref( shift );
	my $pos = $ep->GetCurrentPos;
	$ep->SetSelection( $pos, $pos ) 
}
sub nothing { clear() }

sub word  {
	my $ep = _ep_ref( shift );
	my $pos = $ep->GetCurrentPos;
	$ep->SetSelection(
		$ep->WordStartPosition($pos, 1),
		$ep->WordEndPosition($pos, 1),
	);
}
sub line  {
	my $line = shift;
	my $ep = _ep_ref( shift );
	$line = $ep->GetCurrentLine() unless defined $line;
	$ep->SetSelection($ep->PositionFromLine($line), $ep->GetLineEndPosition($line));
}

sub block {
}
sub all      { &document }
sub document { _ep_ref()->SelectAll }
sub all_if_non {
	my $ep = _ep_ref();
	$ep->SelectAll if $ep->GetSelectionStart == $ep->GetSelectionEnd;
	my ($start, $end) = $ep->GetSelection;
	return $ep->GetTextRange( $start, $end );
}

sub toggle_simple { # selects word line block or nothing
	my $ep = _ep_ref( shift );
	my ($start, $end) = $ep->GetSelection;
	my $pos           = $ep->GetCurrentPos;
	my $line          = $ep->GetCurrentLine();

	# select word if nothing selected
	if ($start == $end){
		$ep->SetSelection(
			$ep->WordStartPosition($pos, 1),
			$ep->WordEndPosition($pos, 1),
		);
		($start, $end) = $ep->GetSelection;
		return if $start != $end;
	}

	if ( $ep->LineFromPosition($start) == $ep->LineFromPosition($end) ) {

		# select line if less then line is selected
		if ($start != $ep->PositionFromLine($line) or $end != $ep->GetLineEndPosition($line)) {
			$ep->SetSelection(
				$ep->PositionFromLine($line),
				$ep->GetLineEndPosition($line),
			);
			($start, $end) = $ep->GetSelection;
			return if $start != $end;
		}

		# select block if line is selected
		to_block_begin();
		$start = $ep->GetSelectionStart();
		to_block_end();
		$end = $ep->GetSelectionEnd();
		my $hline = $ep->LineFromPosition($end);
		$hline-- if $ep->PositionFromLine($hline) == $end;
		$hline-- while $ep->PositionFromLine($hline) == $ep->GetLineEndPosition($hline);
		$ep->SetSelection( $start, $ep->GetLineEndPosition($hline) );
	}
	# select if more then a line was selected
	else { $ep->SetSelection( $pos, $pos ) }
}

sub toggle_content { # selects text inside of < > [] {} () // '' ""
	my $ep = _ep_ref( shift );
	my ($start, $end) = $ep->GetSelection;
	my $pos           = $ep->GetCurrentPos;
	my $line          = $ep->GetCurrentLine();
	my %delimiter = (  
	'>' => '<', ']'=>'[', '}'=>'{', ')'=>'(',
	'/' => '/', '\'' => '\'', '"' => '"'
);


	#$ep->PositionFromLine($line);
	#$ep->GetLineEndPosition($line);
	#$pasttext =~ /([||||||])/
	#/{|}|\(|\)|\[|\]/
	#tr/{}()\[\]//;
	#$`
	#my $matchpos = $ep->BraceMatch(--$pos);
	#to_block_begin();
	#to_block_end();

	#print '',($ep->GetSelection),"\n";
}

1;

__END__

=head1 NAME

Kephra::Edit::Select - calls to select different text parts

=head1 DESCRIPTION

=over 4

=item nothing

=item word

=item line

=item block

=item document

=back

=cut