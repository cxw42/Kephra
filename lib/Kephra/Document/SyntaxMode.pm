package Kephra::Document::SyntaxMode;
our $VERSION = '0.06';

use strict;
use warnings;

my $current;
sub _ID { $current = defined $_[0] ? $_[0] : $current }

# syntaxstyles

sub _get_auto{ &_get_by_fileending }
sub _get_by_fileending {
	my $file_ending = Kephra::Document::Data::get_attribute('ending', shift );
	chop $file_ending if $file_ending and (substr ($file_ending, -1) eq '~');
	my $language_id;
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
	if (_ID() ne $auto_style) { set($auto_style) }
	else                      { set('none')      }
}

sub reload { set( _ID() ) }
sub update { _ID(Kephra::Document::Data::attr('syntaxmode')) }

sub set {
	my $style   = shift;
	my $ep      = Kephra::App::EditPanel::_ref();
	my $color   = \&Kephra::Config::color;
	$style = _get_by_fileending() if $style eq 'auto';
	$style = 'none' unless $style;
	# do nothing when syntaxmode of next doc is the same
	#return if _ID() eq $style;
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
		$ep->SetLexer(&Wx::wxSTC_LEX_NULL);
	} else {
		eval("require syntaxhighlighter::$style");
		eval("syntaxhighlighter::$style" . '::load($ep)');
	}

	# restore bracelight, bracebadlight indentguide colors
	my $indicator = $Kephra::config{editpanel}{indicator};
	my $bracelight = $indicator->{bracelight};
	if ( $bracelight->{visible} ) {
		$ep->StyleSetBold( &Wx::wxSTC_STYLE_BRACELIGHT, 1 );
		$ep->StyleSetBold( &Wx::wxSTC_STYLE_BRACEBAD,   1 );
		$ep->StyleSetForeground
			( &Wx::wxSTC_STYLE_BRACELIGHT, &$color( $bracelight->{good_color} ) );
		$ep->StyleSetBackground
			( &Wx::wxSTC_STYLE_BRACELIGHT, &$color( $bracelight->{back_color} ) );
		$ep->StyleSetForeground
			( &Wx::wxSTC_STYLE_BRACEBAD, &$color( $bracelight->{bad_color} ) );
		$ep->StyleSetBackground
			( &Wx::wxSTC_STYLE_BRACEBAD, &$color( $bracelight->{back_color} ) );
		$ep->StyleSetForeground 
			(&Wx::wxSTC_STYLE_INDENTGUIDE,&$color($indicator->{indent_guide}{color}));
	}

	Kephra::Document::Data::set_attribute( 'syntaxmode', $style );
	_ID($style);
	$ep->Colourise( 0, $ep->GetTextLength ); # refresh editpanel painting
	# cleanup
	Kephra::App::EditPanel::Margin::refresh_changeable_settings();
	Kephra::App::StatusBar::style_info($style);
	return $style;
}

sub compile {}
sub apply_color {}

sub open_file  { Kephra::Config::open_file( 'syntaxhighlighter', "$_[0].pm") }

1;
