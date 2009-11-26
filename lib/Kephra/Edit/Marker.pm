package Kephra::Edit::Marker;
our $VERSION = '0.20';

use strict;
use warnings;

#
# internal data handling subs
#
my @bookmark;
sub bookmark_is_set {
	my $nr = shift;
	return if $nr < 0 or $nr > 9;
	$bookmark[$nr]{set};
}
sub _ep    { Kephra::App::EditPanel::_ref() }
sub _config{ Kephra::API::Config::settings()->{search}{bookmark} }

# checkes if bookmark with given number is still alive an refresh his data
# or deletes data if dead
# my $doc2vis = \&Kephra::App::TabBar::_doc2vis_pos;
sub _refresh_bookmark {
	my $nr = shift;
	my $temp = $bookmark[$nr];

#print "refresh $nr $temp\n";
	# care only about active bookmarks
	return unless bookmark_is_set($nr);
#print "passed\n";

	my $config = $Kephra::config{search}{bookmark}{$nr};
	my $cur_doc_nr = Kephra::Document::Data::current_nr();
	my $ep = _ep();
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
	my $ep         = _ep();
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
			toggle_bookmark( $nr );
		}
	}
}

sub save_all    { 
	_refresh_bookmark($_) for 0..9;
	save_into_file();
}
sub save_into_file {
	#Kephra::API::Config::settings()->{search}
}

sub toggle_bookmark   {
	my $nr = shift;
	my $ep = _ep();
	my $pos = $ep->GetCurrentPos;
	my $line = $ep->GetCurrentLine;
	# is selected bookmark in current line ?
	my $marker_in_line = (1 << $nr) & $ep->MarkerGet($line);
	delete_bookmark($nr);
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
	} # else { $ep->GotoPos($pos) } # old behaviour not yet to delete
}

sub goto_bookmark     {
	my $nr = shift;
	if ( _refresh_bookmark($nr) ) {
#print "goto $nr\n";
#print "toggle $nr ; ".$config->{pos}.":".$temp->{line}." - ".$temp->{col}."\n";
		Kephra::Document::Change::to_nr( $bookmark[$nr]{doc_nr} );
		Kephra::Edit::Goto::pos( $Kephra::config{search}{bookmark}{$nr}{pos} );
	}
}

sub delete_bookmark   {
	my $nr = shift;
	if ( _refresh_bookmark( $nr ) ){
		my $cur_doc_nr = Kephra::Document::Data::current_nr();
		my $ep = Kephra::Document::Data::_ep( $nr );
		Kephra::Document::Data::set_current_nr( $bookmark[$nr]{doc_nr} );
		$ep->MarkerDeleteAll($nr);
		_delete_data($nr);
		Kephra::Document::Data::set_current_nr($cur_doc_nr);
	}
}
sub delete_all_bookmarks  {
	Kephra::Edit::_save_positions();
	delete_bookmark($_) for 0..9;
	Kephra::Edit::_restore_positions();
	Kephra::App::EditPanel::gets_focus( );
}

1;
