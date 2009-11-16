package Kephra::App::EditPanel::Margin;
our $VERSION = '0.09';

use strict;
use warnings;

sub _ep_ref {
	ref $_[0] eq 'Wx::StyledTextCtrl' ? $_[0] : Kephra::App::EditPanel::_ref()   
}
sub _config        { $Kephra::config{editpanel}{margin}}
sub _line_config   { _config()->{linenumber}}
sub _fold_config   { _config()->{fold}      }
sub _marker_config { _config()->{marker}    }
sub width {
	my $ep = _ep_ref(shift);
	my $width;
	$width += $ep->GetMarginWidth($_) for 0..2;
	$width
}
sub in_nr {
	my $x = shift;
	my $ep = _ep_ref(shift);
	my $border;
	for my $margin (0..2){
		$border += $ep->GetMarginWidth($margin);
		return $margin if $x <= $border;
	}
	return -1;
}

sub apply_settings {
	my $ep = _ep_ref(shift);
	# defining the 3 margins
	$ep->SetMarginType( 0, &Wx::wxSTC_MARGIN_SYMBOL );
	$ep->SetMarginType( 1, &Wx::wxSTC_MARGIN_NUMBER );
	$ep->SetMarginType( 2, &Wx::wxSTC_MARGIN_SYMBOL );
	$ep->SetMarginMask( 0, 0x01FFFFFF );
	$ep->SetMarginMask( 1, 0 );
	$ep->SetMarginMask( 2, &Wx::wxSTC_MASK_FOLDERS );
	$ep->SetMarginSensitive( 0, 1 );
	$ep->SetMarginSensitive( 1, 0 );
	$ep->SetMarginSensitive( 2, 1 );

	# setting folding markers
	my $color     = \&Kephra::Config::color;
	my $f = &$color( _fold_config()->{fore_color} );
	my $b = &$color( _fold_config()->{back_color} );
	if (_fold_config()->{style} eq 'arrows') {
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDER,       &Wx::wxSTC_MARK_ARROW,    $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEREND,    &Wx::wxSTC_MARK_ARROW,    $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEROPEN,   &Wx::wxSTC_MARK_ARROWDOWN,$b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEROPENMID,&Wx::wxSTC_MARK_ARROWDOWN,$b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERSUB,    &Wx::wxSTC_MARK_EMPTY,    $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERMIDTAIL,&Wx::wxSTC_MARK_EMPTY,    $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERTAIL,   &Wx::wxSTC_MARK_EMPTY,    $b,$f);
	}
	else {
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDER,       &Wx::wxSTC_MARK_BOXPLUS,  $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEREND,    &Wx::wxSTC_MARK_BOXPLUSCONNECTED,$b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEROPEN,   &Wx::wxSTC_MARK_BOXMINUS, $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDEROPENMID,&Wx::wxSTC_MARK_BOXMINUSCONNECTED,$b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERMIDTAIL,&Wx::wxSTC_MARK_TCORNER,  $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERTAIL,   &Wx::wxSTC_MARK_LCORNER,  $b,$f);
		$ep->MarkerDefine(&Wx::wxSTC_MARKNUM_FOLDERSUB,    &Wx::wxSTC_MARK_VLINE,    $b,$f);
	}
	$ep->SetFoldFlags(16) if _fold_config()->{flag_line};

	show_marker($ep);
	Kephra::Document::Data::set_value('margin_linemax', 0);
	apply_line_number_width($ep);
	apply_line_number_color($ep);
	show_fold($ep);
	apply_text_width($ep);
}
sub refresh_changeable_settings {
	apply_line_number_color(@_);
	apply_fold_flag_color(@_);
}
#
# deciding what to do when clicked on edit panel margin
#
sub on_left_click {
	my ($ep, $event) = @_;
	my $nr = $event->GetMargin();
	toggle_here(@_) if $nr == 2;
}
sub on_middle_click {
	my ($ep, $event, $nr) = @_;
	Kephra::App::EditPanel::Margin::toggle_recursively($ep, $event) if $nr == 2;

}
sub on_right_click {
	my ($ep, $event, $nr) = @_;
	if ($nr == 2) {
		$event->LeftIsDown
			? Kephra::App::EditPanel::Margin::toggle_all()
			: Kephra::App::EditPanel::Margin::toggle_siblings($ep, $event);
	}
}



#
# line number margin
#
sub line_number_visible{ _line_config->{visible} }
sub switch_line_number {
	_line_config->{visible} ^= 1;
	apply_line_number_width()
}

sub set_line_number_width {
	my $config = _line_config();
	$config->{width} = shift;
	apply_line_number_width();
}

sub apply_line_number_width {
	my $ep = _ep_ref(shift);
	my $config = _line_config();
	my $width = $config->{visible}
		? $config->{width} * $Kephra::config{editpanel}{font}{size}
		: 0;
	$ep->SetMarginWidth( 1, $width);
	if ($config->{autosize} and $config->{visible}) {
		Kephra::API::EventTable::add_call ('document.text.change',
			'autosize_line_number', \&line_number_autosize_update);
	} else {
		Kephra::API::EventTable::del_call
			('document.text.change', 'autosize_line_number');
	}
}

sub reset_line_number_width {
	my $config = _line_config();
	my ($max_digits, $lnr_digits);

	if ( $config->{start_with_min} ) {
		$max_digits = $config->{min_width};
		if ((ref $Kephra::document{open} eq 'ARRAY') and $config->{autosize}) {
			my $ep = _ep_ref();
			Kephra::Document::do_with_all( sub {
				$lnr_digits = length $ep->GetLineCount;
				$max_digits = $lnr_digits if $lnr_digits > $max_digits;
			} )
		}
		$config->{width} = $max_digits;
		Kephra::Document::Data::set_value('margin_linemax', 10 ** $max_digits - 1);
	}
	apply_line_number_width();
}


sub autosize_line_number {
	my $config = _line_config();
	return unless $config->{autosize};
	my $need = length _ep_ref->GetLineCount;
	set_line_number_width($need) if $need > $config->{width};
	Kephra::Document::Data::set_value('margin_linemax', 10 ** $need - 1);
}
sub line_number_autosize_update {
	my $line_max = Kephra::Document::Data::get_value('margin_linemax');
	autosize_line_number() if _ep_ref->GetLineCount > $line_max;
}

sub apply_line_number_color {
	my $ep     = _ep_ref(shift);
	my $config = _line_config();
	my $color  = \&Kephra::Config::color;
	$ep->StyleSetForeground(&Wx::wxSTC_STYLE_LINENUMBER,&$color($config->{fore_color}));
	$ep->StyleSetBackground(&Wx::wxSTC_STYLE_LINENUMBER,&$color($config->{back_color}));
}


#
# marker margin
#
sub marker_visible { _marker_config->{visible} }
sub show_marker {
	my $ep = _ep_ref(shift);
	marker_visible()
		? $ep->SetMarginWidth(0, 16)
		: $ep->SetMarginWidth(0,  0);
}
sub switch_marker {
	_marker_config->{visible} ^= 1;
	show_marker();
}


#
# fold margin
#
sub fold_visible { _fold_config()->{visible} }
sub show_fold {
	my $ep  = _ep_ref(shift);
	my $visible = fold_visible();
	my $width = $visible ? 16 : 0;
	$ep->SetProperty('fold' => $visible);
	$ep->SetMarginWidth( 2, $width );
	unfold_all() unless $visible;
}
sub switch_fold {
	_fold_config()->{visible} ^= 1;
	show_fold();
}
sub toggle_here {
	# params you get if triggered by mouse click
	my ($ep, $event ) = @_;
	$ep = _ep_ref();
	my $line = defined $event
		? $ep->LineFromPosition( $event->GetPosition() )
		: $ep->GetCurrentLine();
	$ep->ToggleFold($line);
	Kephra::Edit::Goto::next_visible_pos() if _fold_config()->{keep_caret_visible}
	                                       and not $ep->GetFoldExpanded($line);
}
sub toggle_recursively {
	my $ep = _ep_ref();
	my $line = _get_line(@_);
	my $level = $ep->GetFoldLevel($line);
	unless ( _is_head( $ep->GetFoldLevel($line) ) ) {
		$line = $ep->GetFoldParent($line);
		return if $line == -1;
	}
	my $xp = not $ep->GetFoldExpanded($line);
	my $cursor = $ep->GetLastChild($line, -1);
	while ($cursor >= $line) {
		$ep->ToggleFold($cursor) if $ep->GetFoldExpanded($cursor) xor $xp;
		$cursor--;
	}
	Kephra::Edit::Goto::next_visible_pos() if _fold_config()->{keep_caret_visible};
}
sub toggle_siblings         { toggle_siblings_of_line( _get_line(@_) ) }
sub toggle_siblings_of_line {
	my $ep = _ep_ref();
	my $line = shift;
	return if $line < 0 or $line > ($ep->GetLineCount()-1);
	my $level = $ep->GetFoldLevel($line);
	my $parent = $ep->GetFoldParent($line);
	my $xp = not $ep->GetFoldExpanded($line);
	my $first_line = $parent;
	my $cursor = $ep->GetLastChild($parent, -1 );
	($first_line, $cursor) = (-1, $ep->GetLineCount()-2) if $parent == -1;
	while ($cursor > $first_line){
		$ep->ToggleFold($cursor) if $ep->GetFoldLevel($cursor) == $level
		                         and ($ep->GetFoldExpanded($cursor) xor $xp);
		$cursor--;
	}
	Kephra::Edit::Goto::next_visible_pos() if _fold_config()->{keep_caret_visible}
	                                       and not $xp;
}
sub show_folded_children {
	my $ep = _ep_ref();
	my $parent = _get_line(@_);
	unless ( _is_head( $ep->GetFoldLevel($parent) ) ) {
		$parent = $ep->GetFoldParent($parent);
		return if $parent == -1;
	}
	$ep->ToggleFold($parent) unless $ep->GetFoldExpanded($parent);
	my $cursor = $ep->GetLastChild( $parent, -1 );
	my $level = $ep->GetFoldLevel($parent) >> 16;
	while ($cursor > $parent) {
		$ep->ToggleFold($cursor) if $ep->GetFoldLevel($cursor) % 2048 == $level
		                         and $ep->GetFoldExpanded($cursor);
		$cursor--;
	}
}
sub toggle_all {
	my $ep = _ep_ref();
	my $line = $ep->GetLineCount() - 1;
	# looking for the head of heads // capi di capi
	$line = $ep->GetFoldParent($line) while $ep->GetFoldParent($line) > -1;
	my $xp = $ep->GetFoldExpanded($line);
	$xp ? fold_all() : unfold_all();
	Kephra::Edit::Goto::next_visible_pos() if _fold_config()->{keep_caret_visible}
	                                       and $xp;
}
sub fold_all {
	my $ep  = _ep_ref();
	my $cursor = $ep->GetLineCount()-1;
	while ($cursor > -1) {
		$ep->ToggleFold($cursor) if $ep->GetFoldExpanded($cursor);
		$cursor--;
	}
}
sub unfold_all {
	my $ep  = _ep_ref();
	my $cursor = $ep->GetLineCount()-1;
	while ($cursor > -1) {
		$ep->ToggleFold($cursor) unless $ep->GetFoldExpanded($cursor);
		$cursor--;
	}
}
# is this the fold level of a head node ?
sub _is_head {
	my $level = shift;
	return 1 if ($level % 1024) < (($level >> 16) % 1024);
}
sub _get_line {
	my ($ep, $event ) = @_;
	$ep = _ep_ref();
	my $line;
	if (defined $event) {
		my ($x, $y, $max_y) = (width()+5, $event->GetY, $ep->GetSize->GetHeight);
		my $pos = $ep->PositionFromPointClose($x, $y);
		while ($pos < 0 and $y+10 < $max_y) {
			$y += 10;
			$pos = $ep->PositionFromPointClose($x, $y);
		}
		$line = $ep->LineFromPosition($pos);
	} else { $line = $ep->GetCurrentLine() }
	return $line;
}
sub apply_fold_flag_color {
	_ep_ref()->StyleSetForeground
		(&Wx::wxSTC_STYLE_DEFAULT, Kephra::Config::color(_fold_config()->{fore_color}));
}

#
# extra text margin
#
sub get_text_width { _config->{text} }
sub set_text_width {
	_config->{text} = shift;
	apply_text_width();
}
sub apply_text_width {
	my $ep = _ep_ref(shift);
	my $width = get_text_width();
	$ep->SetMargins( $width, $width );
}

1;
#wxSTC_MARK_MINUS wxSTC_MARK_PLUS wxSTC_MARK_CIRCLE wxSTC_MARK_SHORTARROW
#wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED
