package Kephra::Edit::Bookmark;
our $VERSION = '0.19';

use strict;
use warnings;

#
# internal data handling subs
#
my @bookmark;
sub is_set { 
	my $nr = shift;
	return if $nr < 0 or $nr > 9;
	$bookmark[$nr]{set};
}
# checkes if bookmark with given number is still alive an refresh his data
# or deletes data if dead
sub _refresh_data_nr {
	my $nr = shift;
	my $temp = $bookmark[$nr];

#print "refresh $nr $temp\n";
	# care only about active bookmarks
	return unless is_set($nr);
#print "passed\n";

	my $config = $Kephra::config{search}{bookmark}{$nr};
	my $cur_doc_nr = Kephra::Document::Data::current_nr();
	my $ep = Kephra::App::EditPanel::_ref();
	my $marker_byte = 1 << $nr;
	my $line;

	if ($temp->{doc_nr} < Kephra::Document::Data::count()){
		$ep = Kephra::Document::Data::_ep( $temp->{doc_nr} );
		Kephra::Document::Data::set_current_nr($temp->{doc_nr});
		goto bookmark_found if $marker_byte & $ep->MarkerGet( $temp->{line} );
		if ( $config->{file} eq Kephra::Document::Data::get_file_path($nr) ) {
			$line = $ep->MarkerNext(0, $marker_byte);
			if ($line > -1) {
				$temp->{line} = $line;
				goto bookmark_found;
			}
		}
	}

	my $doc_nr = Kephra::Document::Data::nr_from_file_path( $config->{file} );
	if (ref $doc_nr eq 'ARRAY'){
		for my $doc_nr (@{$doc_nr}){
			$ep = Kephra::Document::Data::_ep( $doc_nr );
			Kephra::Document::Data::set_current_nr($doc_nr);
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
	Kephra::Document::Data::set_current_nr($cur_doc_nr);
	return 0;

bookmark_found:
	# check if goto position fits in current line
	$line = $temp->{line};
	my $ll = $ep->LineLength( $line );
	$temp->{col} = $ll if $temp->{col} > $ll;
	$config->{pos} = $ep->PositionFromLine( $line ) + $temp->{col};
	Kephra::Document::Data::set_current_nr($cur_doc_nr);
	return 1;
}

sub _delete_data {
	my $nr = shift;
	delete $Kephra::config{search}{bookmark}{$nr};
	delete $bookmark[$nr];
}
#
# API
#
sub define_marker {
	my $ep = shift;
	my $conf = Kephra::App::EditPanel::Margin::_config()->{marker};
	my $color= \&Kephra::Config::color;
	my $fore = &$color( $conf->{fore_color} );
	my $back = &$color( $conf->{back_color} );
	$ep->MarkerDefine( $_, &Wx::wxSTC_MARK_SHORTARROW, $fore, $back ) for 0 .. 9;
}

sub restore_all {
	my $ep         = Kephra::App::EditPanel::_ref();
	my $cur_doc_nr = Kephra::Document::Data::current_nr();
	my $bookmark   = $Kephra::config{search}{bookmark};

	for my $nr ( 0 .. 9 ) {
		if ($bookmark->{$nr}){
			next unless $bookmark->{$nr};
			my $doc_nr = Kephra::Document::Data::nr_from_file_path( $bookmark->{$nr}{file} );
			if (ref $doc_nr eq 'ARRAY') { $doc_nr = $doc_nr->[0] }
			else                        { next }
			$ep = Kephra::Document::Data::_ep( $doc_nr );
			$ep->GotoPos( $bookmark->{$nr}{pos} );
			toggle_nr( $nr );
		}
	}
}

sub save_all { _refresh_data_nr($_) for 0..9 }

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
sub toggle_nr   {
	my $nr = shift;
	my $ep = Kephra::App::EditPanel::_ref();
	my $pos = $ep->GetCurrentPos;
	my $line = $ep->GetCurrentLine;
	# is selected bookmark in current line ?
	my $marker_in_line = (1 << $nr) & $ep->MarkerGet($line);
	delete_nr($nr);
	unless ($marker_in_line) {
		my $temp = $bookmark[$nr];
		my $config = $Kephra::config{search}{bookmark}{$nr};
		$ep->MarkerAdd( $line, $nr);
		$config->{file} = Kephra::Document::Data::file_path();
		$config->{pos}  = $pos;
		$temp->{doc_nr} = Kephra::Document::Data::current_nr() || 0;
		$temp->{col}    = $config->{pos} - $ep->PositionFromLine($line);
		$temp->{line}   = $line;
		$temp->{set}    = 1;
		$ep->GotoPos( $pos );
	} else { $ep->GotoPos($pos) }
}


sub goto_nr_0  { goto_nr( 0 ) }
sub goto_nr_1  { goto_nr( 1 ) }
sub goto_nr_2  { goto_nr( 2 ) }
sub goto_nr_3  { goto_nr( 3 ) }
sub goto_nr_4  { goto_nr( 4 ) }
sub goto_nr_5  { goto_nr( 5 ) }
sub goto_nr_6  { goto_nr( 6 ) }
sub goto_nr_7  { goto_nr( 7 ) }
sub goto_nr_8  { goto_nr( 8 ) }
sub goto_nr_9  { goto_nr( 9 ) }
sub goto_nr    {
	my $nr = shift;
	if ( _refresh_data_nr($nr) ) {
print "goto $nr\n";
#print "toggle $nr ; ".$config->{pos}.":".$temp->{line}." - ".$temp->{col}."\n";
		Kephra::Document::Change::to_nr( $bookmark[$nr]{doc_nr} );
		Kephra::Edit::Goto::pos( $Kephra::config{search}{bookmark}{$nr}{pos} );
	}
}

sub delete_nr  {
	my $nr = shift;
	if ( _refresh_data_nr( $nr ) ){
		my $cur_doc_nr = Kephra::Document::Data::current_nr();
		my $ep = Kephra::Document::Data::_ep( $nr );
		Kephra::Document::Data::set_current_nr( $bookmark[$nr]{doc_nr} );
		$ep->MarkerDeleteAll($nr);
		_delete_data($nr);
		Kephra::Document::Data::set_current_nr($cur_doc_nr);
	}
}
sub delete_all {
	Kephra::Edit::_save_positions();
	delete_nr($_) for 0..9;
	Kephra::Edit::_restore_positions();
	Wx::Window::SetFocus(Kephra::App::EditPanel::_ref());
}

1;
