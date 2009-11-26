package Kephra::Document::Property;
our $VERSION = '0.04';

=head1 NAME

Kephra::Document::Property - 

=head1 DESCRIPTION

change doc data and eval it.

=cut

use strict;
use warnings;


# some internal shortcut helper
sub _ep_ref     { Kephra::App::EditPanel::_ref() }
sub _doc_nr     { 
	defined $_[0]
		? Kephra::Document::Data::validate_doc_nr($_[0])
		: Kephra::Document::Data::current_nr();
}
sub _is_current { $_[0] == Kephra::Document::Data::current_nr() }
sub _get_attr   { Kephra::Document::Data::get_attribute(@_) }
sub _set_attr   { Kephra::Document::Data::set_attribute(@_) }
#
# general API for single and multiple values (getter/setter)
#
sub get {
	my $property = shift;
	my $doc_nr = _doc_nr(shift);
	return if $doc_nr < 0;
	if    (not ref $property)        { _get_attr($property, $doc_nr) }
	elsif (ref $property eq 'ARRAY') {
		my @result;
		push @result, _get_attr($_, $doc_nr) for @$property;
		\@result;
	}
}
sub _set{
	my ($key, $v) = @_;
	return unless defined $v;
	return set_codepage($v)  if $key eq 'codepage';
	return set_EOL_mode($v)  if $key eq 'EOL';
	return set_readonly($v)  if $key eq 'readonly';
	return set_syntaxmode($v)if $key eq 'syntaxmode';
	return set_tab_size($v)  if $key eq 'tab_size';
	return set_tab_mode($v)  if $key eq 'tab_use';
}
sub set {
	if (not ref $_[0] and defined $_[1]){_set(@_)}
	elsif ( ref $_[0] eq 'HASH')        {_set($_, $_[0]->{$_}) for keys %{$_[0]}} 
}
sub get_file { _get_attr('file_path') }
sub set_file {
	my ($file, $nr) = @_;
	$nr = _doc_nr($nr);
	return if $nr < 0;
	Kephra::Document::Data::set_file_path($file, $nr);
	Kephra::App::TabBar::refresh_label($nr);
	Kephra::App::Window::refresh_title() if _is_current($nr);
}
#
# property specific API
#
sub get_codepage { _get_attr('codepage', $_[0]) }
sub set_codepage {
	my ($value, $nr) = @_;
	$nr = _doc_nr($nr);
	return if $nr < 0 or not defined $value;
	_set_attr('codepage', $value, $nr);
	#_ep_ref()->SetCodePage( $value );
	Kephra::App::StatusBar::codepage_info($value);
}#use Wx::STC qw(&Wx::wxSTC_CP_UTF8); Wx::wxUNICODE()
sub switch_codepage {
	set_codepage( get_codepage( _doc_nr() ) eq '8bit' ? 'utf8' : '8bit' );
}
#
# tab size
#
sub get_tab_size { _get_attr('tab_size', $_[0]) }
sub set_tab_size {
	my ($size, $nr) = @_;
	$nr = _doc_nr($nr);
	return if not $size or $nr < 0;
	my $ep = _ep_ref();
	$ep->SetTabWidth($size);
	$ep->SetIndent($size);
	$ep->SetHighlightGuide($size);
	_set_attr('tab_size', $size, $nr);
}
sub set_tab_size_2 { set_tab_size(2) }
sub set_tab_size_3 { set_tab_size(3) }
sub set_tab_size_4 { set_tab_size(4) }
sub set_tab_size_5 { set_tab_size(5) }
sub set_tab_size_6 { set_tab_size(6) }
sub set_tab_size_8 { set_tab_size(8) }
#
# tab use
#
sub get_tab_mode { _get_attr('tab_use', $_[0]) }
sub set_tab_mode {
	my $mode = shift;
	my $nr = _doc_nr(shift);
	return if $nr < 0;
	my $ep = _ep_ref();
	if ($mode eq 'auto') {
		my $line;
		for my $lnr (0 .. $ep->GetLineCount()-1){
			$line = $ep->GetLine($lnr);
			if ($line =~ /^( |\t)/) {
				$mode = $1 eq ' ' ? 0 : 1;
				last;
			}
		}
	}
	$ep->SetUseTabs($mode);
	_set_attr('tab_use', $mode, $nr);
	Kephra::App::StatusBar::tab_info() if _is_current($nr);
}
sub set_tabs_hard  { set_tab_mode(1) }
sub set_tabs_soft  { set_tab_mode(0) }
sub switch_tab_mode{ get_tab_mode() ? set_tab_mode(0) : set_tab_mode(1) }
#
# EOL
#
sub EOL_length   { _get_attr('EOL_length') }
sub get_EOL_mode { _get_attr('EOL') }
sub set_EOL_mode {
	my $ep = _ep_ref();
	my $mode = shift;
	$mode = $Kephra::config{file}{defaultsettings}{EOL_new} if !$mode;
	if ($mode eq 'OS') {
		if    (&Wx::wxMSW) {$mode = 'cr+lf'}
		elsif (&Wx::wxMAC) {$mode = 'cr'   }
		else              {$mode = 'lf'   }
	}
	$mode = detect_EOL_mode() if $mode eq 'auto';
	my $eoll = 1;
	if ( $mode eq 'cr+lf'or $mode eq 'win') {$ep->SetEOLMode(&Wx::wxSTC_EOL_CRLF); 
		$eoll = 2;
	}
	elsif ( $mode eq 'cr'or $mode eq 'mac') {$ep->SetEOLMode(&Wx::wxSTC_EOL_CR) }
	else                                    {$ep->SetEOLMode(&Wx::wxSTC_EOL_LF) } 
	_set_attr('EOL',        $mode);
	_set_attr('EOL_length', $eoll);
	Kephra::App::StatusBar::EOL_info($mode);
}

sub set_EOL_mode_lf   { set_EOL_mode('lf') }
sub set_EOL_mode_cr   { set_EOL_mode('cr') }
sub set_EOL_mode_crlf { set_EOL_mode('cr+lf') }
sub set_EOL_mode_auto { set_EOL_mode('auto' ) }
sub set_EOL_mode_OS   { set_EOL_mode('OS') }

sub convert_EOL {
	my $ep = _ep_ref();
	my $mode  = shift;
	my $doc_nr = _doc_nr(shift);
	$mode = $Kephra::config{file}{defaultsettings}{EOL_open} unless $mode;
	$mode = detect_EOL_mode() if $mode eq 'auto';
	Kephra::API::EventTable::freeze_group('edit');
	if ($mode eq 'cr+lf' or $mode eq 'win')  {$ep->ConvertEOLs(&Wx::wxSTC_EOL_CRLF)}
	elsif ($mode eq 'cr' or $mode eq 'mac' ) {$ep->ConvertEOLs(&Wx::wxSTC_EOL_CR)}
	else                                     {$ep->ConvertEOLs(&Wx::wxSTC_EOL_LF)}
	Kephra::API::EventTable::thaw_group('edit');
	set_EOL_mode($mode);
}

sub convert_EOL_2_lf   { convert_EOL('lf') }
sub convert_EOL_2_cr   { convert_EOL('cr') }
sub convert_EOL_2_crlf { convert_EOL('cr+lf') }
sub detect_EOL_mode {
	my $ep = _ep_ref();
	my $end_pos   = $ep->PositionFromLine(1);
	my $begin_pos = $end_pos - 3;
	$begin_pos = 0 if $begin_pos < 0;
	my $text = $ep->GetTextRange( $begin_pos, $end_pos );

	if ( length($text) < 1 ) { return 'auto' }
	else {
		return 'cr+lf' if $text =~ /\r\n/;
		return 'cr'    if $text =~ /\r/;
		return 'lf'    if $text =~ /\n/;
		return 'auto';
	}
}


#
# auto indention
#
sub get_autoindention { $Kephra::config{editpanel}{auto}{indention} }
sub switch_autoindention { 
	$Kephra::config{editpanel}{auto}{indention} ^= 1;
	Kephra::Edit::eval_newline_sub();
}
sub set_autoindent_on   {
	$Kephra::config{editpanel}{auto}{indention}  = 1; 
	Kephra::Edit::eval_newline_sub();
}
sub set_autoindent_off  { 
	$Kephra::config{editpanel}{auto}{indention}  = 0;
	Kephra::Edit::eval_newline_sub();
}

#
# brace indention
#
sub get_braceindention{ $Kephra::config{editpanel}{auto}{brace}{indention}}
sub switch_braceindention{ 
	$Kephra::config{editpanel}{auto}{brace}{indention} ^= 1;
	Kephra::Edit::eval_newline_sub();
}
sub set_blockindent_on {
	$Kephra::config{editpanel}{auto}{brace}{indention} = 1;
	Kephra::Edit::eval_newline_sub();
}
sub set_blockindent_off {
	$Kephra::config{editpanel}{auto}{brace}{indention} = 0;
	Kephra::Edit::eval_newline_sub();
}

#
# write protection
#
sub get_readonly { _get_attr('readonly') }
sub set_readonly {
	my $status = shift;
	my $ep     = _ep_ref();
	if (not $status or $status eq 'off' ) {
		$ep->SetReadOnly(0);
		$status = 'off';
	} elsif ( $status eq 'on' or $status eq '1' ) {
		$ep->SetReadOnly(1);
		$status = 'on';
	} elsif ( $status eq 'protect' or $status eq '2' ) {
		my $file = Kephra::Document::Data::get_file_path();
		if ( $file and not -w $file ) {$ep->SetReadOnly(1)}
		else                          {$ep->SetReadOnly(0)}
		$status = 'protect';
	}
	_set_attr('readonly', $status);
	$status = $ep->GetReadOnly ? 1 : 0;
	_set_attr('editable', $status);
	Kephra::App::TabBar::refresh_current_label()
		if $Kephra::config{app}{tabbar}{info_symbol};
}
sub set_readonly_on      { set_readonly('on') }
sub set_readonly_off     { set_readonly('off') }
sub set_readonly_protect { set_readonly('protect') }
#
# syntaxmode
#
sub get_syntaxmode { _get_attr('syntaxmode') }
sub set_syntaxmode { Kephra::Document::SyntaxMode::set(@_) }

1;