package Kephra::Edit::Bookmark;
our $VERSION = '0.18';

use strict;
use warnings;

use Wx qw(wxSTC_MARK_SHORTARROW);

# internal subs

sub is_set{ 
	my $nr = shift;
	$Kephra::temp{search}{bookmark}{$nr}{set};
}
# checkes if bookmark with given number is still alive an refresh his data
# or deletes data if dead
sub _refresh_data_nr {
	my $nr = shift;
	my $temp = $Kephra::temp{search}{bookmark}{$nr};

	# care only about active bookmarks
	return unless $temp->{set};

	my $config = $Kephra::config{search}{bookmark}{$nr};
	my $cur_doc_nr = Kephra::Document::current_nr();
	my $ep = Kephra::App::EditPanel::_ref();
	my $marker_byte = 1 << $nr;
	my $line;

	if ($temp->{doc_nr} < Kephra::Document::get_count()){
		Kephra::Document::Internal::change_pointer($temp->{doc_nr});
		goto bookmark_found if $marker_byte & $ep->MarkerGet( $temp->{line} );
		if ( $config->{file} eq Kephra::Document::get_file_path($nr) ) {
			$line = $ep->MarkerNext(0, $marker_byte);
			if ($line > -1) {
				$temp->{line} = $line;
				goto bookmark_found;
			}
		}
	}

	my $doc_nr = Kephra::Document::nr_from_file_path( $config->{file} );
	if (ref $doc_nr eq 'ARRAY'){
		for my $doc_nr (@{$doc_nr}){
			Kephra::Document::Internal::change_pointer($doc_nr);
			$line = $ep->MarkerNext(0, $marker_byte);
			if ($line > -1){
				$temp->{doc_nr} = $doc_nr;
				$temp->{line} = $line;
				goto bookmark_found;
			}
		}
	}

bookmark_disappeared:
	_delete_data($nr);
	Kephra::Document::Internal::change_pointer($cur_doc_nr);
	return 0;

bookmark_found:
	# check if goto position fits in current line
	$line = $temp->{line};
	my $ll = $ep->LineLength( $line );
	$temp->{col} = $ll if $temp->{col} > $ll;
	$config->{pos} = $ep->PositionFromLine( $line ) + $temp->{col};
	Kephra::Document::Internal::change_pointer($cur_doc_nr);
	return 1;
}

sub _delete_data {
	my $nr = shift;
	delete $Kephra::config{search}{bookmark}{$nr};
	delete $Kephra::temp{search}{bookmark}{$nr};
}
#
# API
#
sub define_marker {
	my $conf       = $Kephra::config{editpanel}{margin}{marker};
	my $color      = \&Kephra::Config::color;
	my $foreground = &$color( $conf->{fore_color} );
	my $background = &$color( $conf->{back_color} );
	my $edit_panel = Kephra::App::EditPanel::_ref();
	for my $i ( 0 .. 9 ) {
		$edit_panel->MarkerDefine
			( $i, wxSTC_MARK_SHORTARROW, $foreground, $background )
	}
}

sub restore_all {
	my $edit_panel = Kephra::App::EditPanel::_ref();
	my $cur_doc_nr = Kephra::Document::current_nr();
	my $bookmark   = $Kephra::config{search}{bookmark};

	for my $nr ( 0 .. 9 ) {
		if ($bookmark->{$nr}){
			next unless $bookmark->{$nr};
			my $doc_nr = Kephra::Document::nr_from_file_path( $bookmark->{$nr}{file} );
			if (ref $doc_nr eq 'ARRAY') { $doc_nr = $doc_nr->[0] }
			else                        { next }
			Kephra::Document::Internal::change_pointer( $doc_nr );
			$edit_panel->GotoPos( $bookmark->{$nr}{pos} );
			toggle_nr( $nr );
		}
	}
	Kephra::Document::Internal::change_pointer($cur_doc_nr);
}

sub save_all { _refresh_data_nr($_) for 0..9 }

sub toggle_nr {
	my $nr = shift;
	my $edit_panel = Kephra::App::EditPanel::_ref();
	my $pos = $edit_panel->GetCurrentPos;
	my $line = $edit_panel->GetCurrentLine;
	# is selected bookmark in current line ?
	my $marker_in_line = (1 << $nr) & $edit_panel->MarkerGet($line);

	delete_nr($nr);
	unless ($marker_in_line) {
		my $temp = \%{$Kephra::temp{search}{bookmark}{$nr}};
		my $config = \%{$Kephra::config{search}{bookmark}{$nr}};
		$edit_panel->MarkerAdd( $line, $nr);
		$config->{file} = Kephra::Document::file_path();
		$config->{pos}  = $pos;
		$temp->{doc_nr} = Kephra::Document::current_nr();
		$temp->{col}    = $config->{pos} - $edit_panel->PositionFromLine($line);
		$temp->{line}   = $line;
		$temp->{set}    = 1;
		$edit_panel->GotoPos( $pos );
	} else { $edit_panel->GotoPos($pos) }
}

sub toggle_nr_0 { toggle_nr( 0 ) }
sub toggle_nr_1 { toggle_nr( 1 ) }
sub toggle_nr_2 { toggle_nr( 2 ) }
sub toggle_nr_3 { toggle_nr( 3 ) }
sub toggle_nr_4 { toggle_nr( 4 ) }
sub toggle_nr_5 { toggle_nr( 5 ) }
sub toggle_nr_6 { toggle_nr( 6 ) }
sub toggle_nr_7 { toggle_nr( 7 ) }
sub toggle_nr_8 { toggle_nr( 8 ) }
sub toggle_nr_9 { toggle_nr( 9 ) }

sub goto_nr {
	my $nr = shift;
	if ( _refresh_data_nr($nr) ) {
		Kephra::Document::Change::to_number
			( $Kephra::temp{search}{bookmark}{$nr}{doc_nr} );
		Kephra::Edit::Goto::pos( $Kephra::config{search}{bookmark}{$nr}{pos} );
	}
}

sub goto_nr_0 { goto_nr( 0 ) }
sub goto_nr_1 { goto_nr( 1 ) }
sub goto_nr_2 { goto_nr( 2 ) }
sub goto_nr_3 { goto_nr( 3 ) }
sub goto_nr_4 { goto_nr( 4 ) }
sub goto_nr_5 { goto_nr( 5 ) }
sub goto_nr_6 { goto_nr( 6 ) }
sub goto_nr_7 { goto_nr( 7 ) }
sub goto_nr_8 { goto_nr( 8 ) }
sub goto_nr_9 { goto_nr( 9 ) }

sub delete_all {
	Kephra::Edit::_save_positions();
	delete_nr($_) for 0..9;
	Kephra::Edit::_restore_positions();
	Wx::Window::SetFocus(Kephra::App::EditPanel::_ref());
}

sub delete_nr {
	my $nr = shift;
	if ( _refresh_data_nr( $nr ) ){
		my $edit_panel = Kephra::App::EditPanel::_ref();
		my $cur_doc_nr = Kephra::Document::current_nr();

		Kephra::Document::Internal::change_pointer(
			$Kephra::temp{search}{bookmark}{$nr}{doc_nr}
		);
		$edit_panel->MarkerDeleteAll($nr);
		_delete_data($nr);
		Kephra::Document::Internal::change_pointer($cur_doc_nr);
	}
}

1;
