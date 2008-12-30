package Kephra::App::EditPanel::Margin;
our $VERSION = '0.06';

use strict;
use warnings;

use Wx qw( wxID_ANY
	wxSTC_STYLE_DEFAULT wxSTC_STYLE_LINENUMBER
	wxSTC_MASK_FOLDERS  wxSTC_MARGIN_SYMBOL wxSTC_MARGIN_NUMBER
	wxSTC_MARKNUM_FOLDEREND wxSTC_MARK_BOXPLUSCONNECTED
	wxSTC_MARKNUM_FOLDEROPENMID wxSTC_MARK_BOXMINUSCONNECTED
	wxSTC_MARKNUM_FOLDERMIDTAIL wxSTC_MARK_TCORNER
	wxSTC_MARKNUM_FOLDERTAIL wxSTC_MARK_LCORNER
	wxSTC_MARKNUM_FOLDERSUB wxSTC_MARK_VLINE
	wxSTC_MARKNUM_FOLDER wxSTC_MARK_BOXPLUS
	wxSTC_MARKNUM_FOLDEROPEN wxSTC_MARK_BOXMINUS
);
use Wx::Event qw(EVT_STC_MARGINCLICK);
#wxSTC_MARK_MINUS wxSTC_MARK_PLUS wxSTC_MARK_CIRCLE 
#wxSTC_MARKNUM_FOLDEREND wxSTC_MARK_SHORTARROW
#wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED

sub _ep_ref        {  Kephra::App::EditPanel::_ref()   }
sub _config        { $Kephra::config{editpanel}{margin}}
sub _line_config   { _config()->{linenumber}}
sub _fold_config   { _config()->{fold}      }
sub _marker_config { _config()->{marker}    }
sub width {
	my $width;
	my $ep = _ep_ref;
	$width += $ep->GetMarginWidth($_) for 0..2;
	$width
}
sub in_nr {
	my $x = shift;
	my $ep = _ep_ref;
	my $border;
	for my $margin (0..2){
		$border += $ep->GetMarginWidth($margin);
		return $margin if $x <= $border;
	}
	return -1;
}

sub apply_settings {
	my $ep = _ep_ref();
	# defining the 3 margins
	$ep->SetMarginType( 0, wxSTC_MARGIN_SYMBOL );
	$ep->SetMarginType( 1, wxSTC_MARGIN_NUMBER );
	$ep->SetMarginType( 2, wxSTC_MARGIN_SYMBOL );
	$ep->SetMarginMask( 0, 0x01FFFFFF );
	$ep->SetMarginMask( 1, 0 );
	$ep->SetMarginMask( 2, wxSTC_MASK_FOLDERS );
	$ep->SetMarginSensitive( 0, 1 );
	$ep->SetMarginSensitive( 1, 0 );
	$ep->SetMarginSensitive( 2, 1 );

	# setting folding markers
	my $color     = \&Kephra::Config::color;
	my $f = &$color( _fold_config()->{fore_color} );
	my $b = &$color( _fold_config()->{back_color} );
	$ep->MarkerDefine(wxSTC_MARKNUM_FOLDEREND,wxSTC_MARK_BOXPLUSCONNECTED, $b, $f);
	$ep->MarkerDefine(wxSTC_MARKNUM_FOLDEROPENMID,wxSTC_MARK_BOXMINUSCONNECTED,$b,$f);
	$ep->MarkerDefine(wxSTC_MARKNUM_FOLDERMIDTAIL,wxSTC_MARK_TCORNER,  $b, $f);
	$ep->MarkerDefine(wxSTC_MARKNUM_FOLDERTAIL,   wxSTC_MARK_LCORNER,  $b, $f);
	$ep->MarkerDefine(wxSTC_MARKNUM_FOLDERSUB,    wxSTC_MARK_VLINE,    $b, $f);
	$ep->MarkerDefine(wxSTC_MARKNUM_FOLDER,       wxSTC_MARK_BOXPLUS,  $b, $f);
	$ep->MarkerDefine(wxSTC_MARKNUM_FOLDEROPEN,   wxSTC_MARK_BOXMINUS, $b, $f);
	$ep->SetFoldFlags(16) if _fold_config()->{flag_line};

	$Kephra::temp{margin_linemax} = 0;
	show_marker();
	apply_line_number_width();
	apply_line_number_color();
	show_fold();
	apply_text_width();
}
sub refresh_changeable_settings {
	apply_line_number_color();
	apply_fold_flag_color();
}

sub on_click {
	my ($ep, $event ) = @_;
	toggle_here(@_) if $event->GetMargin() == 2;
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
	my $config = _line_config();
	my $width = $config->{visible}
		? $config->{width} * $Kephra::config{editpanel}{font}{size}
		: 0;
	_ep_ref->SetMarginWidth( 1, $width);
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
		$Kephra::temp{margin_linemax} = 10 ** $max_digits - 1;
	}
	apply_line_number_width();
}


sub autosize_line_number {
	my $config = _line_config();
	return unless $config->{autosize};
	my $need = length _ep_ref->GetLineCount;
	set_line_number_width($need) if $need > $config->{width};
	$Kephra::temp{margin_linemax} = 10 ** $need - 1;
}
sub line_number_autosize_update {
	autosize_line_number()
		if _ep_ref->GetLineCount > $Kephra::temp{margin_linemax};
}

sub apply_line_number_color {
	my $ep     = _ep_ref();
	my $config = _line_config();
	my $color  = \&Kephra::Config::color;
	$ep->StyleSetForeground(wxSTC_STYLE_LINENUMBER,&$color($config->{fore_color}));
	$ep->StyleSetBackground(wxSTC_STYLE_LINENUMBER,&$color($config->{back_color}));
}


#
# marker margin
#
sub marker_visible { _marker_config->{visible} }
sub show_marker {
	marker_visible()
		? _ep_ref->SetMarginWidth(0, 16)
		: _ep_ref->SetMarginWidth(0,  0);
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
	my $visible = fold_visible();
	my $width = $visible ? 16 : 0;
	my $ep  = _ep_ref();
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
	Kephra::Edit::Goto::next_visible_pos() if _fold_config()->{keep_caret_visible};
}
sub toggle_siblings {
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
	}
	else { $line = $ep->GetCurrentLine() }
	my $level = $ep->GetFoldLevel($line);
	my $parent = $ep->GetFoldParent($line);
	my $xp = not $ep->GetFoldExpanded($line); 
	my $first_line = $parent;
	my $cursor = $ep->GetLastChild($parent, $ep->GetFoldLevel($parent) );
	($first_line, $cursor) = (-1, $ep->GetLineCount()-2) if $parent == -1;
	my ($cparent, $clevel);
	while ($cursor > $first_line){
		$clevel = $ep->GetFoldLevel($cursor);
		$ep->ToggleFold($cursor) if $clevel == $level 
		                         and ($ep->GetFoldExpanded($cursor) xor $xp);
		$cursor--;
	}
	Kephra::Edit::Goto::next_visible_pos() if _fold_config()->{keep_caret_visible};
}
sub unfold_all {
	my $ep  = _ep_ref();
	my $cursor = 0;
	my $last = $ep->GetLineCount()-1;
	while ($cursor < $last) {
		$ep->ToggleFold($cursor) unless $ep->GetFoldExpanded($cursor);
		$cursor++;
	}
}
sub apply_fold_flag_color {
	_ep_ref()->StyleSetForeground
		(wxSTC_STYLE_DEFAULT, Kephra::Config::color(_fold_config()->{fore_color}));
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
	my $width = get_text_width();
	_ep_ref()->SetMargins( $width, $width );
}

1;