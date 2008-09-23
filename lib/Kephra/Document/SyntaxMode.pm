package Kephra::Document::SyntaxMode;
our $VERSION = '0.03';

use strict;
use warnings;


use Wx qw(
	wxSTC_LEX_NULL wxSTC_STYLE_DEFAULT
	wxSTC_STYLE_BRACELIGHT wxSTC_STYLE_BRACEBAD wxSTC_STYLE_INDENTGUIDE
);

sub _ID {
	if (defined $_[0]) { $Kephra::temp{current}{syntaxmode} = $_[0] }
	else               { $Kephra::temp{current}{syntaxmode}         }
}

# syntaxstyles

sub _get_auto{ &_get_by_fileending }
sub _get_by_fileending {
	my $file_ending = Kephra::Document::Internal::get_tmp_value('ending', shift );
	my $language_id;
	chop $file_ending if $file_ending and (substr ($file_ending, -1) eq '~');
	if ($file_ending) {
		$language_id = $Kephra::temp{file}{end2langmap}
				{ Kephra::Config::_lc_utf($file_ending) };
	} else                                     { return "none" }
	if ( !$language_id  or $language_id eq '') { return "none" }
	elsif ( $language_id eq 'text' )           { return "none" }
	return $language_id;
}

sub switch_auto {
	my $auto_style = _get_auto();
	if (_ID() ne $auto_style) {change_to($auto_style)}
	else                      {change_to('none')     }
}

sub reload { change_to( _ID() ) }

sub change_to {
	my $ep      = Kephra::App::EditPanel::_ref();
	my $color   = \&Kephra::Config::color;
	my $style   = shift;
	$style = _get_by_fileending() if $style eq 'auto';
	$style = 'none' unless $style;
	# do nothing when syntaxmode of next doc is the same
	return if _ID() eq $style;

	# prevent clash between big lexer & indicator
	if ( $style =~ /asp|html|php|xml/ ) { $ep->SetStyleBits(7) }
	else                                { $ep->SetStyleBits(5) }

	# clear style infos
	$ep->StyleResetDefault;
	Kephra::App::EditPanel::load_font();
	$ep->StyleClearAll;
	$ep->SetKeyWords( $_, '' ) for 0 .. 1;

	# load syntax style
	if ( $style eq 'none' ) { 
		$ep->SetLexer(wxSTC_LEX_NULL);
	} else {
		eval("require syntaxhighlighter::$style");
		eval("syntaxhighlighter::$style" . '::load($ep)');
	}

	# restore bracelight, bracebadlight indentguide colors
	my $indicator = $Kephra::config{editpanel}{indicator};
	my $bracelight = $indicator->{bracelight};
	if ( $bracelight->{visible} ) {
		$ep->StyleSetBold( wxSTC_STYLE_BRACELIGHT, 1 );
		$ep->StyleSetBold( wxSTC_STYLE_BRACEBAD,   1 );
		$ep->StyleSetForeground
			( wxSTC_STYLE_BRACELIGHT, &$color( $bracelight->{good_color} ) );
		$ep->StyleSetForeground
			( wxSTC_STYLE_BRACEBAD, &$color( $bracelight->{bad_color} ) );
		$ep->StyleSetForeground 
			(wxSTC_STYLE_INDENTGUIDE,&$color($indicator->{indent_guide}{color}));
	}

	Kephra::Document::Internal::set_attribute( 'syntaxmode', $style );
	_ID($style);
	$ep->Colourise( 0, $ep->GetTextLength ); # refresh editpanel painting
	$ep->SetCodePage(65001);
	# cleanup
	Kephra::App::EditPanel::Margin::apply_color();
	Kephra::App::StatusBar::style_info($style);
	return $style;
}

sub compile {}
sub apply_color {}

1;
