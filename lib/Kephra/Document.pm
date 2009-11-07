package Kephra::Document;
our $VERSION = '0.53';

=pod
 creating and closing a doc, internals,
 converter that take whole doc into account
=cut

use strict;
use warnings;

sub new   {   # make document empty and reset all document properties to default
	my $old_nr = Kephra::Document::Data::current_nr();
	my $doc_nr = new_if_allowed('new');
	Kephra::Document::Data::set_previous_nr( $old_nr );
	Kephra::Document::Data::set_current_nr( $doc_nr );
	Kephra::App::TabBar::raise_tab_by_doc_nr($doc_nr);
	&reset($doc_nr);
}

sub reset {   # restore once opened file from its settings
	my $doc_nr = Kephra::Document::Data::validate_doc_nr(shift);
	my $ep = Kephra::Document::Data::_ep( $doc_nr );
	Kephra::Document::Property::set_readonly(0, $doc_nr);
	$ep->ClearAll;
	$ep->EmptyUndoBuffer;
	$ep->SetSavePoint;
	Kephra::Document::Data::default_attributes($doc_nr, '');
	Kephra::Document::Data::evaluate_attributes($doc_nr);
	Kephra::App::StatusBar::refresh_all_cells();
}


sub restore { # add newly opened file from known settings
	my %file_settings = %{ shift; };
	my $file = $file_settings{file_path};
	my $config = $Kephra::config{file};
	if ( -e $file ) {
		# open only text files and empty files
		return if $config->{open}{only_text} == 1 and -B $file;
		# check if file is already open and goto this already opened
		return if $config->{open}{each_once} == 1 
		      and Kephra::Document::Data::file_already_open($file);
		my $doc_nr = new_if_allowed('restore');
		load_file_in_buffer($file);
		Kephra::Document::Data::set_all_attributes(\%file_settings, $doc_nr);
		Kephra::Document::Data::set_file_path($file, $doc_nr);
	}
}


sub add {     # create a new document if settings allow it
	my $file = shift;
	my $config = $Kephra::config{file};
	my $old_nr = Kephra::Document::Data::current_nr();
	if ( defined $file and -e $file ) {
		$file = Kephra::Config::standartize_path_slashes( $file );
		# open only text files and empty files
		return if -B $file and $Kephra::config{file}{open}{only_text} == 1;
		# check if file is already open and goto this already opened
		my $other_nr = Kephra::Document::Data::nr_from_file_path($file);
		return Kephra::Document::Change::to_nr( $other_nr )
			if $config->{open}{each_once} == 1 and $other_nr > -1;

		# save constantly changing settings
		Kephra::Document::Data::update_attributes();
		# create new edit panel
		my $doc_nr = new_if_allowed('add') || 0;
		# was a new doc allowed ?
		return if $doc_nr > 0 and $doc_nr == $old_nr;

		Kephra::Document::Data::set_current_nr($doc_nr);
		Kephra::Document::Data::set_previous_nr($old_nr);
		load_file_in_buffer($file, Kephra::Document::Data::_ep($doc_nr));
		# load default settings for doc attributes
		Kephra::Document::Data::default_attributes($doc_nr, $file);
#print Kephra::Document::Data::_attributes()->[$doc_nr]->{file_name}," = open\n";
		Kephra::Document::Data::evaluate_attributes($doc_nr);
		Kephra::Document::Property::convert_EOL()
			unless $config->{defaultsettings}{EOL_open} eq 'auto';

		Kephra::App::Window::refresh_title();
		#Kephra::App::TabBar::refresh_label($doc_nr);
		Kephra::App::TabBar::raise_tab_by_doc_nr($doc_nr);
		Kephra::App::EditPanel::Margin::autosize_line_number();
		Kephra::API::EventTable::trigger('document.list');
	}
}

sub new_if_allowed {
	# new(empty), add(open) restore(open session)
	my $mode = shift;
	my $ep   = Kephra::App::EditPanel::_ref();
	my $file = Kephra::Document::Data::get_file_path();
	my $old_doc_nr= Kephra::Document::Data::current_nr();
	my $new_doc_nr= Kephra::Document::Data::get_value('buffer');
	my $config    = $Kephra::config{file}{open};

	# check settings
	# in single doc mode close previous doc first
	if ( $config->{single_doc} == 1 ) {
		Kephra::File::close_current();
		return 0;
	}
	unless ( $mode eq 'new' ) {
		if ($ep->GetText eq '' and $ep->GetModify == 0 and (!$file or !-e $file)){
			return $old_doc_nr
				if ($config->{into_empty_doc} == 1)
				or ($config->{into_only_empty_doc} == 1 and $new_doc_nr == 1 );
		}
	}
	# still there? good, now we make a new document
	Kephra::Document::Data::create_slot($new_doc_nr);
	Kephra::App::TabBar::add_edit_tab($new_doc_nr);
	Kephra::App::EditPanel::apply_settings
		( Kephra::Document::Data::_ep($new_doc_nr) );
	Kephra::Document::Data::inc_value('buffer');
	return $new_doc_nr;
}

sub load_file_in_buffer {
	my $file = shift || '';
	#$doc_nr = shift;
	my $ep = shift || Kephra::App::EditPanel::_ref();
	return unless Kephra::App::EditPanel::is( $ep );
	$ep->ClearAll();
	Kephra::File::IO::open_pipe($file, $ep);
	$ep->EmptyUndoBuffer;
	$ep->SetSavePoint;
	Kephra::File::_remember_save_moment($file);
	Kephra::Document::Data::inc_value('loaded');
}
############################################################################
sub convert_indent2tabs   { _edit( \&Kephra::Edit::Convert::indent2tabs  )}
sub convert_indent2spaces { _edit( \&Kephra::Edit::Convert::indent2spaces)}
sub convert_spaces2tabs   { _edit( \&Kephra::Edit::Convert::spaces2tabs  )}
sub convert_tabs2spaces   { _edit( \&Kephra::Edit::Convert::tabs2spaces  )}
sub del_trailing_spaces   { _edit( \&Kephra::Edit::Format::del_trailing_spaces)}

sub _edit{
	my $coderef = shift;
	return unless ref $coderef eq 'CODE';
	Kephra::Edit::_save_positions();
	Kephra::Edit::Select::all();
	&$coderef();
	Kephra::Edit::_restore_positions();
	1;
}

sub do_with_all {
	my $code = shift;
	return unless ref $code eq 'CODE';
	my $nr = Kephra::Document::Data::current_nr();
	my $attr = Kephra::Document::Data::_attributes();
	Kephra::Document::Data::update_attributes();
	for ( @{ Kephra::Document::Data::all_nr() } ) {
		Kephra::Document::Data::set_current_nr($_);
		&$code( $attr->[$_] );
	}
	Kephra::Document::Data::set_current_nr($nr);
	Kephra::Document::Data::evaluate_attributes($nr);
}

1;
