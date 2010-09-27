package Kephra::Edit::Select;
our $VERSION = '0.08';

use strict;
use warnings;
sub _ep_ref { Kephra::App::EditPanel::is( shift ) || Kephra::App::EditPanel::_ref() }
sub _line_empty {
	my $line = shift;
	my $ep = _ep_ref( shift );
	$line = $ep->GetCurrentLine() unless defined $line;
	return $ep->PositionFromLine($line) == $ep->GetLineEndPosition($line);
}
#
sub get_block_start {
	my $pos = shift;
	my $ep = _ep_ref( shift );
	$pos = $ep->GetCurrentPos unless defined $pos;
	my $line = $ep->LineFromPosition($pos);
	return $pos if _line_empty($line);
	return $pos if _line_empty($line-1) and $pos == $ep->PositionFromLine($line);
	my $cpos = $ep->GetCurrentPos;
	$ep->SetCurrentPos( $pos );
	$ep->CmdKeyExecute(&Wx::wxSTC_CMD_PARAUP);
	$pos = $ep->GetCurrentPos;
	$ep->SetCurrentPos( $cpos );
	return $pos;
}

sub get_block_end {
	my $pos = shift;
	my $ep = _ep_ref( shift );
	$pos = $ep->GetCurrentPos unless defined $pos;
	my $line = $ep->LineFromPosition($pos);
	return $pos if _line_empty($line);
	return $pos if _line_empty($line+1) and $pos == $ep->GetLineEndPosition($line);
	my $cpos = $ep->GetCurrentPos;
	$ep->SetCurrentPos( $pos );
	$ep->CmdKeyExecute(&Wx::wxSTC_CMD_PARADOWN);
	$line = $ep->GetCurrentLine();
	$line--;
	$line-- until $ep->PositionFromLine($line)!=$ep->GetLineEndPosition($line);
	$pos = $ep->GetLineEndPosition($line);
	$ep->SetCurrentPos( $cpos );
	return $pos;
}

sub to_block_begin{ _ep_ref()->CmdKeyExecute(&Wx::wxSTC_CMD_PARAUPEXTEND)   }
sub to_block_end  { _ep_ref()->CmdKeyExecute(&Wx::wxSTC_CMD_PARADOWNEXTEND) }
#
sub nothing {
	my $ep = _ep_ref( shift );
	my $pos = $ep->GetCurrentPos;
	$ep->SetSelection( $pos, $pos ) 
}

sub word {
	my $pos = shift;
	my $ep = _ep_ref( shift );
	$pos = $ep->GetCurrentPos unless defined $pos;
	$ep->SetSelection($ep->WordStartPosition($pos,1),$ep->WordEndPosition($pos,1));
}
sub line  {
	my $line = shift;
	my $ep = _ep_ref( shift );
	$line = $ep->GetCurrentLine() unless defined $line;
	$ep->SetSelection($ep->PositionFromLine($line),$ep->GetLineEndPosition($line));
}

sub block {
	my $pos = shift;
	my $ep = _ep_ref( shift );
	$pos = $ep->GetCurrentPos unless defined $pos;
	$ep->SetSelection( get_block_start($pos), get_block_end($pos) );
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
	my ($start, $end)= $ep->GetSelection; # initial selection
	my $startline    = $ep->LineFromPosition($start);
	my $endline      = $ep->LineFromPosition($end);

	return if _line_empty($startline) and _line_empty($endline);

	# try select word, if already more selected, do a line
	if ($startline == $endline){
		word($start);
		my ($probestart, $probeend) = $ep->GetSelection;
		return unless $start <= $probestart and $end >= $probeend;
		line();
		($probestart, $probeend) = $ep->GetSelection;
		return unless $start == $probestart and $end == $probeend;
	}

	my $blockstart = get_block_start($start);
	my $blockend = get_block_end($end);

	# select nothing because block was selected
	return nothing() if $start == $blockstart and $end == $blockend;

	$ep->SetSelection($blockstart, $blockend);
}

sub toggle_content { # selects text inside of < > [] {} () '' ""
	my $ep = _ep_ref( shift );
	my ($start, $end)= $ep->GetSelection;
	my $startline    = $ep->LineFromPosition($start);
	my $endline      = $ep->LineFromPosition($end);
	my %delimiter = (  
	'>' => '<', ']'=>'[', '}'=>'{', ')'=>'(',
	'/' => '/', '\'' => '\'', '"' => '"'
);
# quote styles: 6 7 re styles 17, 18
#$ep->GetTextRange(
#$ep->PositionFromLine($line)  $ep->GetLineEndPosition($line);
#$ep->BraceMatch($newpos)
	#my $blockstart = get_block_start($start);
	#my $blockend = get_block_end($end);
	#$ep->PositionFromLine($line);
	#$ep->GetLineEndPosition($line);
	#$pasttext =~ /([||||||])/
	#/{|}|\(|\)|\[|\]/
	#tr/{}()\[\]//;
	#$`
	#my $matchpos = $ep->BraceMatch(--$pos);

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