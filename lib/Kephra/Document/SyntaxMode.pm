package Kephra::Document::SyntaxMode;
$VERSION = '0.02';

use strict;
use Wx qw(
	wxSTC_LEX_NULL wxSTC_STYLE_DEFAULT
	wxSTC_STYLE_BRACELIGHT wxSTC_STYLE_BRACEBAD wxSTC_STYLE_INDENTGUIDE
);

# syntaxstyles
sub set {$Kephra::document{current}{syntaxmode} = shift }
sub get {$Kephra::document{current}{syntaxmode} 
	if exists $Kephra::document{current}{syntaxmode}
}

sub _get_auto{ &_get_by_fileending }
sub _get_by_fileending {
	my $file_ending = Kephra::Document::get_tmp_value('ending', shift );
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
	if (get() ne $auto_style) {change_to($auto_style)}
	else                      {change_to('none')     }
}

sub reload { change_to( get() ) }

sub change_to {
	my $ep      = Kephra::App::EditPanel::_get();
	my $color   = \&Kephra::Config::color;
	my $style   = shift;
	$style = _get_by_fileending() if $style eq 'auto';
	$style = 'none' unless $style;

	# prevent clash between big lexer & indicator
	if ( $style =~ /asp|html|php|xml/ ) { $ep->SetStyleBits(7) }
	else                                { $ep->SetStyleBits(5) }

	# clear style infos
	$ep->StyleClearAll;
	$ep->StyleResetDefault;
	Kephra::App::EditPanel::load_font();
	$ep->SetKeyWords( 0, '' );

	# load syntax style
	if ( $style eq 'none' ) { 
		$ep->SetLexer(wxSTC_LEX_NULL)
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

	# cleanup
	set($style);
	$ep->Colourise( 0, $ep->GetTextLength ); # refresh editpanel painting
	Kephra::App::EditPanel::Margin::apply_color();
	Kephra::App::StatusBar::style_info($style);
	return $style;
}

1;