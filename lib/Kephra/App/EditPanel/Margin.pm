package Kephra::App::EditPanel::Margin;
our $VERSION = '0.04';

use strict;
use warnings;


use Wx qw(
	wxSTC_STYLE_LINENUMBER
	wxSTC_MARGIN_SYMBOL wxSTC_MARGIN_NUMBER
	wxSTC_MASK_FOLDERS
);
#wxSTC_MARK_MINUS wxSTC_MARK_PLUS wxSTC_MARK_CIRCLE wxSTC_MARK_BOXPLUS
#wxSTC_MARKNUM_FOLDEREND wxSTC_MARK_SHORTARROW
#wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED

sub _ep_ref        {  Kephra::App::EditPanel::_ref() }
sub _config        { $Kephra::config{editpanel}{margin} }
sub _line_config   { _config()->{linenumber} }
sub _marker_config { _config()->{marker} }

sub apply_settings{
	my $ep = _ep_ref();
	# build
	$ep->SetMarginType( 0, wxSTC_MARGIN_SYMBOL );
	$ep->SetMarginType( 1, wxSTC_MARGIN_NUMBER );
	$ep->SetMarginType( 2, wxSTC_MARGIN_SYMBOL );
	$ep->SetMarginMask( 0, 0x01FFFFFF );
	$ep->SetMarginMask( 1, 0 );
	$ep->SetMarginMask( 2, wxSTC_MASK_FOLDERS );
	$ep->SetMarginSensitive( 0, 1 );
	$ep->SetMarginSensitive( 1, 0 );
	$ep->SetMarginSensitive( 2, 1 );

	$Kephra::temp{margin_linemax} = 0;
	show_marker();
	apply_line_number_width();
	apply_color();
	show_fold();
	apply_text_width();
}


# line number margin
sub line_number_visible{ _line_config->{visible} }

sub switch_line_number {
	_line_config->{visible} ^= 1;
	apply_line_number_width()
}

sub set_line_number_width{
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

sub reset_line_number_width{
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

sub apply_color {
	my $ep     = _ep_ref();
	my $config = _line_config();
	my $color  = \&Kephra::Config::color;
	$ep->StyleSetForeground(wxSTC_STYLE_LINENUMBER,&$color($config->{fore_color}));
	$ep->StyleSetBackground(wxSTC_STYLE_LINENUMBER,&$color($config->{back_color}));
}


# marker margin

sub marker_visible{ _marker_config->{visible} }
sub show_marker {
	marker_visible()
		? _ep_ref->SetMarginWidth(0, 16)
		: _ep_ref->SetMarginWidth(0,  0);
}
sub switch_marker {
	_marker_config->{visible} ^= 1;
	show_marker();
}


# fold margin
sub fold_visible{ _config->{fold} }
sub show_fold {
	my $width = fold_visible() ? 16 : 0;
	_ep_ref->SetMarginWidth( 2, $width );
}
sub switch_fold {
	_config->{fold} ^= 1;
	show_fold();
}

# extra text margin
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
