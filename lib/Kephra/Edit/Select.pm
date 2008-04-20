package Kephra::Edit::Select;
$VERSION = '0.03';

# text selection

use strict;
use Wx qw( wxSTC_CMD_PARAUPEXTEND wxSTC_CMD_PARADOWNEXTEND );

sub _ep_ref { Kephra::App::EditPanel::_ref() }

sub all      { &document }
sub document { _ep_ref()->SelectAll }
sub all_if_non {
	my $ep = _ep_ref();
	$ep->SelectAll if $ep->GetSelectionStart == $ep->GetSelectionEnd;
	my ($start, $end) = $ep->GetSelection;
	return $ep->GetTextRange( $start, $end );
}

sub to_block_begin{ _ep_ref()->CmdKeyExecute(wxSTC_CMD_PARAUPEXTEND)   }
sub to_block_end  { _ep_ref()->CmdKeyExecute(wxSTC_CMD_PARADOWNEXTEND) }

1;