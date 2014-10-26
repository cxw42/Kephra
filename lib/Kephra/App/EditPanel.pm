package Kephra::App::EditPanel;
use strict;
use warnings;

our $VERSION = '0.10';

# visual settings of the Edit Panel

use Wx qw(
		wxDEFAULT wxNORMAL wxLIGHT wxBOLD wxSLANT wxITALIC
		wxSTC_CACHE_PAGE
		wxSTC_EDGE_LINE wxSTC_EDGE_NONE     wxSTC_WRAP_NONE wxSTC_WRAP_WORD
		wxSTC_STYLE_DEFAULT wxSTC_STYLE_BRACELIGHT wxSTC_STYLE_BRACEBAD
);
#
# internal API to config und app pointer
#
sub _ref {
	if (ref $_[0] eq 'Wx::StyledTextCtrl'){ $Kephra::app{editpanel} = $_[0] }
	else                                  { $Kephra::app{editpanel} }
}
sub _config           { $Kephra::config{editpanel} }
sub _indicator_config { _config()->{indicator} }
#
# settings
#
sub create {
	my $ep = Wx::StyledTextCtrl->new( Kephra::App::Window::_ref() );
	$ep->DragAcceptFiles(1) if Wx::wxMSW();
	_ref($ep);
	return $ep;
}

sub gets_focus { Wx::Window::SetFocus( _ref() ) }

sub apply_settings {
	my $ep        = _ref() or _create();
	my $conf      = _config();
	my $indicator = _indicator_config();
	my $color     = \&Kephra::Config::color;
	$Kephra::temp{edit}{caret}{positions} = ();

	# text visuals: font whitespaces
	load_font();
	apply_whitespace_settings();
	$ep->SetWhitespaceForeground
		( 1, &$color( $indicator->{whitespace}{color} ) );

	# indicators: caret, selection, ...
	$ep->SetCaretLineBack( &$color( $indicator->{caret_line}{color} ) );
	$ep->SetCaretPeriod( $indicator->{caret}{period} );
	$ep->SetCaretWidth( $indicator->{caret}{width} );
	$ep->SetCaretForeground( &$color( $indicator->{caret}{color} ) );
	if ( $indicator->{selection}{fore_color} ne '-1' ) {
		$ep->SetSelForeground
			( 1, &$color( $indicator->{selection}{fore_color} ) );
	}
	$ep->SetSelBackground( 1,&$color( $indicator->{selection}{back_color}));
	apply_EOL_settings();
	apply_LLI_settings();
	apply_caret_line_settings();
	apply_indention_guide_settings();

	# Margins on left side
	Kephra::App::EditPanel::Margin::apply_settings();

	#misc: scroll width, codepage, wordchars
	apply_autowrap_settings();

	$ep->SetScrollWidth($conf->{scroll_width}) 
		unless $conf->{scroll_width} eq 'auto';

	$ep->SetCodePage(65001);
	set_word_chars();

	# internal
	$ep->SetLayoutCache(wxSTC_CACHE_PAGE);
	$ep->SetBufferedDraw(1);

	apply_bracelight_settings();
	Kephra::Edit::eval_newline_sub();
}

sub set_word_chars { 
	my $ep   = _ref();
	my $conf = _config();
	if ( $conf->{word_chars} ) {
		$ep->SetWordChars( '$%-@_abcdefghijklmnopqrstuvwxyz����ABCDEFGHIJKLMNOPQRSTUVWXYZ���0123456789' );
		#$ep->SetWordChars( $conf->{word_chars} );
	} else {
		$ep->SetWordChars( '$%-@_abcdefghijklmnopqrstuvwxyz����ABCDEFGHIJKLMNOPQRSTUVWXYZ���0123456789' );
	}
}

sub set_tab_size {
	my $ep   = _ref();
	my $size = shift;
	$ep->SetTabWidth($size);
	$ep->SetIndent($size);
	$ep->SetHighlightGuide($size);
}
#
# line wrap
#
sub apply_autowrap_settings {
	_ref()->SetWrapMode( _config()->{line_wrap} );
	Kephra::API::EventTable::trigger('editpanel.autowrap');
}

sub get_autowrap_mode { _config()->{line_wrap} == wxSTC_WRAP_WORD}

sub switch_autowrap_mode {
	_config()->{line_wrap} = get_autowrap_mode()
		? wxSTC_WRAP_NONE
		: wxSTC_WRAP_WORD;
	apply_autowrap_settings();
}


#
# bracelight
#

sub bracelight_visible{ _indicator_config()->{bracelight}{visible} }

sub apply_bracelight_settings{
	if (bracelight_visible()){
		Kephra::API::EventTable::add_call
			('caret.move', 'bracelight', \&paint_bracelight);
		paint_bracelight();
	} else {
		Kephra::API::EventTable::del_call('caret.move', 'bracelight');
		_ref()->BraceHighlight( -1, -1 );
	}
}

sub paint_bracelight {
	my $ep       = _ref();
	my $pos      = $ep->GetCurrentPos;
	my $matchpos = $ep->BraceMatch(--$pos);
	$matchpos = $ep->BraceMatch(++$pos) if $matchpos == -1;

	$ep->SetHighlightGuide(0);
	if ( $matchpos > -1 ) {
		# highlight braces
		$ep->BraceHighlight($matchpos, $pos);
		# asign pos to opening brace
		$pos = $matchpos if $matchpos < $pos;
		my $indent = $ep->GetLineIndentation( $ep->LineFromPosition($pos) );
		# highlighting indenting guide
		$ep->SetHighlightGuide($indent)
			if $indent % $Kephra::document{current}{tab_size} == 0;
	} else {
		# disbale all highlight
		$ep->BraceHighlight( -1, -1 );
		$ep->BraceBadLight($pos-1)
			if $ep->GetTextRange($pos-1,$pos) =~ /{|}|\(|\)|\[|\]/;
		$ep->BraceBadLight($pos)
			if $pos < $ep->GetTextLength
			and $ep->GetTextRange( $pos, $pos + 1 ) =~ tr/{}()\[\]//;
	}
}

         ##############
         # indicators #
         ##############
#
# indention guide
#
sub indention_guide_visible { 
	_indicator_config()->{indent_guide}{visible} 
}
sub apply_indention_guide_settings {
	_ref->SetIndentationGuides( indention_guide_visible() )
}
sub switch_indention_guide_visibility {
	_indicator_config()->{indent_guide}{visible} ^= 1;
	apply_indention_guide_settings();
}
#
# caret line
#
sub caret_line_visible {
	_indicator_config()->{caret_line}{visible} 
}
sub apply_caret_line_settings { 
	_ref()->SetCaretLineVisible( caret_line_visible() ) 
}
sub switch_caret_line_visibility {
	_indicator_config()->{caret_line}{visible} ^= 1;
	apply_caret_line_settings();
}
#
# LLI = long line indicator = right margin
#
sub LLI_visible { 
	_indicator_config()->{right_margin}{style} == wxSTC_EDGE_LINE
}
sub apply_LLI_settings {
	my $ep = _ref();
	my $config = _indicator_config()->{right_margin};
	my $color   = \&Kephra::Config::color;

	$ep->SetEdgeColour( &$color( $config->{color} ) );
	$ep->SetEdgeColumn( $config->{position} );
	show_LLI( $config->{style} );
}
sub show_LLI { _ref->SetEdgeMode( shift ) }
sub switch_LLI_visibility {
	my $style = _indicator_config()->{right_margin}{style} = LLI_visible()
		? wxSTC_EDGE_NONE
		: wxSTC_EDGE_LINE;
	show_LLI($style);
}
#
# EOL = end of line marker
#
sub EOL_visible { 
	_indicator_config()->{end_of_line_marker}
}
sub switch_EOL_visibility {
	_config()->{indicator}{end_of_line_marker} ^= 1;
	apply_EOL_settings();
}
sub apply_EOL_settings {
	_ref()->SetViewEOL( EOL_visible() ) 

}
#
# whitespace
#
sub whitespace_visible { 
	_indicator_config()->{whitespace}{visible} 
}
sub apply_whitespace_settings {
	_ref()->SetViewWhiteSpace( whitespace_visible() )
}
sub switch_whitespace_visibility {
	my $v = _indicator_config()->{whitespace}{visible} ^= 1;
	apply_whitespace_settings();
	return $v;
}
#
# font settings
#
sub load_font {
	my $ep = _ref();
	my ( $fontweight, $fontstyle ) = ( wxNORMAL, wxNORMAL );
	my $font = _config()->{font};
	$fontweight = wxLIGHT  if $font->{weight} eq 'light';
	$fontweight = wxBOLD   if $font->{weight} eq 'bold';
	$fontstyle  = wxSLANT  if $font->{style}  eq 'slant';
	$fontstyle  = wxITALIC if $font->{style}  eq 'italic';
	my $wx_font = Wx::Font->new( $font->{size}, wxDEFAULT, 
		$fontstyle, $fontweight, 0, $font->{family} );
	$ep->StyleSetFont( wxSTC_STYLE_DEFAULT, $wx_font ) if $wx_font->Ok > 0;
}
sub change_font {
	my ( $fontweight, $fontstyle ) = ( wxNORMAL, wxNORMAL );
	my $font_config = _config()->{font};
	$fontweight = wxLIGHT  if ( $$font_config{weight} eq 'light' );
	$fontweight = wxBOLD   if ( $$font_config{weight} eq 'bold' );
	$fontstyle  = wxSLANT  if ( $$font_config{style}  eq 'slant' );
	$fontstyle  = wxITALIC if ( $$font_config{style}  eq 'italic' );
	my $oldfont = Wx::Font->new( $$font_config{size}, wxDEFAULT, $fontstyle,
		$fontweight, 0, $$font_config{family} );
	my $newfont = Kephra::Dialog::get_font( Kephra::App::Window::_ref(), $oldfont );

	if ( $newfont->Ok > 0 ) {
		($fontweight, $fontstyle) = ($newfont->GetWeight, $newfont->GetStyle);
		$$font_config{size}   = $newfont->GetPointSize;
		$$font_config{family} = $newfont->GetFaceName;
		$$font_config{weight} = 'normal';
		$$font_config{weight} = 'light' if $fontweight == wxLIGHT;
		$$font_config{weight} = 'bold' if $fontweight == wxBOLD;
		$$font_config{style}  = 'normal';
		$$font_config{style}  = 'slant' if $fontstyle == wxSLANT;
		$$font_config{style}  = 'italic' if $fontstyle == wxITALIC;
		&load_font;
		Kephra::Document::SyntaxMode::reload();
		Kephra::App::EditPanel::Margin::apply_line_number_width();
	}
}

1;

#Kephra::Dialog::msg_box(undef,$fr,"");
#use Wx::STC qw(wxSTC_CP_UTF8 wxSTC_CP_UTF16); #wxSTC_CP_UTF8 Wx::wxUNICODE()
#wxSTC_WS_INVISIBLE wxSTC_WS_VISIBLEALWAYS
#$ep->GetSelectionMode;
#$ep->StyleSetForeground (wxSTC_STYLE_CONTROLCHAR, Wx::Colour->new(0x55, 0x55, 0x55));
#$ep->StyleSetBackground (wxSTC_STYLE_CONTROLCHAR, Wx::Colour->new(0xff, 0xff, 0xff));
#$ep->SetScrollWidth($Kephra::config{'editpanel'}{'scroll_width'}); #defaultbreite
#$ep->CallTipShow(3,"testtooltip\n next line"); #tips
#$ep->SetSelectionMode(wxSTC_SEL_RECTANGLE); #rect selection
