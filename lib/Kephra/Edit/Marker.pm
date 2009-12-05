package Kephra::Edit::Marker;
our $VERSION = '0.21';

=head1 NAME

Kephra::Edit::Marker - bookmark and marker functions

=head1 DESCRIPTION

Marker are position in the document, that are marked by symbols in the margin
on the left side. Every document can have many Marker.

But there are only 10 bookmarks numbered from 0 to 9.

=cut


use strict;
use warnings;
#
# internal data handling subs
#
my @bookmark; # 0 .. 9
my $marker_nr = 10;    # pos remembered by edit control
sub bookmark_is_set {
	my $nr = shift;
	return if $nr < 0 or $nr > 9;
	$bookmark[$nr]{set};
}
sub _ep    { Kephra::App::EditPanel::_ref() }
sub _config{ Kephra::API::settings()->{search} }
sub _refresh_bookmark_data { # checks if this bookmark is still valid
	# refresh or deletes data data if necessary
	my $nr = shift;
	return unless bookmark_is_set($nr);
	my $bm_data = $bookmark[$nr];
	my $doc_nr = Kephra::Document::Data::validate_doc_nr( $bm_data->{doc_nr} );
	$doc_nr = Kephra::Document::Data::nr_from_file_path($bm_data->{file})
		if Kephra::Document::Data::get_file_path($doc_nr) ne $bm_data->{file};
	_delete_bookmark_data($nr), return 0 if $doc_nr == -1;
	$bm_data->{doc_nr} = $doc_nr;
	my $ep = Kephra::Document::Data::_ep($doc_nr);
	my $line = $ep->MarkerNext(0, (1 << $nr) );
	_delete_bookmark_data($nr), return 0 if $line == -1;
	my $ll = $ep->LineLength( $line );
	if ($bm_data->{col} > $ll) {
		$bm_data->{col} = $ll;
		$bm_data->{pos} = $ep->PositionFromLine( $line ) + $bm_data->{col};
	}
	return $bm_data->{line} = $line;
}

sub _delete_bookmark_data {
	my $nr = shift;
	return if $nr < 0 or $nr > 9;
	$bookmark[$nr] = {};
}
#
# external API
#
sub define_marker {
	my $ep = shift;
	my $conf = Kephra::App::EditPanel::Margin::_config()->{marker};
	my $color= \&Kephra::Config::color;
	my $fore = &$color( $conf->{fore_color} );
	my $back = &$color( $conf->{back_color} );
	$ep->MarkerDefineBitmap
		( $_, Kephra::CommandList::get_cmd_property
			( 'bookmark-goto-'.$_, 'icon' ) ) for 0 .. 9;
	$ep->MarkerDefine( $marker_nr, &Wx::wxSTC_MARK_CIRCLE, $fore, $back );
# wxSTC_MARK_SHORTARROW wxSTC_MARK_ROUNDRECT wxSTC_MARK_CIRCLE
}

sub restore_all {
	my $file = Kephra::Config::filepath( 
		Kephra::Config::Global::_sub_dir(),
		_config()->{data_file},
	);
	my $config_tree = Kephra::Config::File::load($file);
	for my $nr ( 0 .. 9 ) {
		if ( defined $config_tree->{bookmark}{$nr}){
			my $bm_data = $config_tree->{bookmark}{$nr};
			next unless ref $bm_data eq 'HASH' and $bm_data->{file} and $bm_data->{pos};
			$bookmark[$nr]{file} = $bm_data->{file};
			my $bookmark = $bookmark[$nr];
			my $doc_nr = $bookmark->{doc_nr} = 
				Kephra::Document::Data::nr_from_file_path( $bm_data->{file} );
			next if $doc_nr < 0;
			my $ep      = Kephra::Document::Data::_ep($doc_nr);
			my $pos = $bookmark->{pos} = $bm_data->{pos};
			my $line = $bookmark->{line} = $ep->LineFromPosition( $pos );
			$bookmark->{col} = $pos - $ep->PositionFromLine( $line );
			$bookmark->{set} = 1 if $ep->MarkerAdd( $line, $nr ) > -1;
		}
	}
}

sub save_all    {
	_refresh_bookmark_data($_) for 0..9;
	save_into_file();
}
sub save_into_file {
	my $file = Kephra::Config::filepath( 
		Kephra::Config::Global::_sub_dir(),
		Kephra::API::settings()->{search}{data_file},
	);
	my $config_tree = Kephra::Config::File::load($file);
	$config_tree->{bookmark} = {};
	for my $nr (0 .. $#bookmark) {
		next unless bookmark_is_set($nr);
		$config_tree->{bookmark}{$nr}{file} = $bookmark[$nr]{file};
		$config_tree->{bookmark}{$nr}{pos} = $bookmark[$nr]{pos};
	}
	Kephra::Config::File::store($file, $config_tree);
}

# bookmarks
sub toggle_bookmark   {
	my $nr = shift;
	my $ep = _ep();
	my $pos = $ep->GetCurrentPos;
	my $line = $ep->GetCurrentLine;
	# if bookmark is not in current line it will be set 
	my $marker_in_line = (1 << $nr) & $ep->MarkerGet($line);
	delete_bookmark($nr);
	unless ($marker_in_line) {
		my $bookmark = $bookmark[$nr];
		$bookmark->{file} = Kephra::Document::Data::file_path();
		$bookmark->{pos}  = $pos;
		$bookmark->{doc_nr} = Kephra::Document::Data::current_nr();
		$bookmark->{col}    = $pos - $ep->PositionFromLine($line);
		$bookmark->{line}   = $line;
		$bookmark->{set}    = 1 if $ep->MarkerAdd( $line, $nr) > -1;
	}
}

sub goto_bookmark     {
	my $nr = shift;
	if ( _refresh_bookmark_data($nr) ) {
		Kephra::Document::Change::to_nr( $bookmark[$nr]{doc_nr} );
		Kephra::Edit::Goto::pos( $bookmark[$nr]{pos} );
	}
}

sub delete_bookmark   {
	my $nr = shift;
	if ( _refresh_bookmark_data( $nr ) ){
		my $ep = Kephra::Document::Data::_ep( $bookmark[$nr]->{doc_nr} );
		$ep->MarkerDeleteAll($nr);
		_delete_bookmark_data($nr);
	}
}
sub delete_all_bookmarks { delete_bookmark($_) for 0..9 }

# marker
sub toggle_marker_in_line { # generic set / delete marker in line
	my $line = shift;
	my $ep = _ep();
	($ep->MarkerGet($line) & (1 << $marker_nr))
		? $ep->MarkerDelete( $line, $marker_nr)
		: $ep->MarkerAdd( $line, $marker_nr);
}
sub toggle_marker_here    { # toggle triggered by margin left click
	my ($ep, $event ) = @_;
	return unless ref $event eq 'Wx::StyledTextEvent';
#print $event->ControlDown,"\n";
	toggle_marker_in_line( _ep()->LineFromPosition( $event->GetPosition() ) );
}
sub toggle_marker         { # toggle triggered by keyboard / icon
	toggle_marker_in_line( _ep()->GetCurrentLine )
}
sub goto_prev_marker {
	my $ep = _ep();
	my $config = _config()->{marker};
	my $search_byte = $config->{any} ? (1 << $marker_nr+1)-1 : 1 << $marker_nr;
	my $line = $ep->MarkerPrevious( $ep->GetCurrentLine - 1, $search_byte );
	$line = $ep->MarkerPrevious( $ep->LineFromPosition( $ep->GetTextLength), $search_byte )
		if $line == -1 and $config->{wrap};
	Kephra::Edit::Goto::line_nr( $line ) if $line > -1;
}

sub goto_next_marker {
	my $ep = _ep();
	my $config = _config()->{marker};
	my $search_byte = $config->{any} ? (1 << $marker_nr+1)-1 : 1 << $marker_nr;
	my $line = $ep->MarkerNext( $ep->GetCurrentLine + 1, $search_byte );
	$line = $ep->MarkerNext( 0, $search_byte )
		if $line == -1 and $config->{wrap};
	Kephra::Edit::Goto::line_nr( $line ) if $line > -1;
}
sub delete_all_marker_in_doc {
	my $doc_nr = Kephra::Document::Data::valid_or_current_doc_nr(shift);
	my $ep = Kephra::Document::Data::_ep($doc_nr);
	$ep->MarkerDeleteAll($marker_nr);
}
sub delete_all_marker { 
	$_->MarkerDeleteAll($marker_nr) for @{Kephra::Document::Data::get_all_ep()};
}

1;