package Kephra::API::CommandList;
our $VERSION = '0.15';

=head1 NAME

Kephra::API::CommandList - external API for user callable functions

=head1 DESCRIPTION

The CommandList is a dynamically changeable list, that contains all the 
function calls for every menu item, toolbar button and most other widget items.
It holds also label, help text, key binding, icon and more for each command.
All these properties have to be changed globally here in a clean way.
These commands where used by different gui elements, that allows menu and
toolbar definitions to be very compact, readable and and easy changeable.

Names of commands contain dashes as separator of namespaces.

=head1 SPECIFICATION 

CommandlistItem

=over 4

=item * ID - unique identifier, hashkey, following hash is its value

=item * call - CODEREF : actual action, performed when this command is called

=item * enable - CODEREF : returns enable status (0 for disable)

=item * enable_event - string : API::EventTable ID when to check to en/disable

=item * state - CODEREF : that returns state value (for switches)

=item * state_event - string : API::EventTable ID when to check is state changed 

=item * label - string : descriptive name

=item * help - string : short help sentence

=item * key - string : label of key binding

=item * keycode - numeric keycode

=item * icon - Wx::Bitmap

=back

=cut

use strict;
use warnings;

use Wx qw(
	WXK_ESCAPE WXK_BACK WXK_RETURN WXK_TAB WXK_SPACE
	WXK_DELETE WXK_INSERT WXK_HOME WXK_END WXK_PAGEUP WXK_PAGEDOWN
	WXK_UP WXK_DOWN WXK_LEFT WXK_RIGHT
	WXK_F1 WXK_F2 WXK_F3 WXK_F4 WXK_F5 WXK_F6 WXK_F7 WXK_F8 WXK_F9 WXK_F10
	WXK_F11 WXK_F12 
	WXK_NUMPAD_ENTER
);
use YAML::Tiny();


my %list;  # the real commandlist 
sub data  { if (ref $_[0] eq 'HASH') { %list = %{$_[0]}  } else { \%list } }
sub clear  { %list = () }
sub file   { Kephra::Config::filepath( _config()->{file}) }
sub _config{ $Kephra::config{app}{commandlist} }

#sub load_cache  { %list = %{ YAML::Tiny::LoadFile( $_[0] ) }}
#sub store_cache { YAML::Tiny::DumpFile( \%list ) }
# @hash1{keys %hash2} = values %hash2;


# refactor commandlist definition & localisation data into a format that can be
# evaled and used by gui parts
sub load {
	my $cmd_list_def = Kephra::Config::File::load_from_node_data( _config() );
	$cmd_list_def = Kephra::Config::Default::commandlist() unless $cmd_list_def;
	assemble_data($cmd_list_def);
}


sub assemble_data {
	my $cmd_list_def = shift;
	no strict;
	local ($leaf_type, $cmd_id, $target_leafe);
	# copy data of a hash structures into specified commandlist leafes
	for my $key ( qw{call enable enable_event state state_event key icon} ) {
		_copy_values_of_nested_list($cmd_list_def->{$key}, $key);
	}
	my $l18n = Kephra::Config::Localisation::strings();
	_copy_values_of_nested_list($l18n->{commandlist}{label},'label');
	_copy_values_of_nested_list($l18n->{commandlist}{help}, 'help');
	numify_key_code( keys %list );
	undef $leaf_type;
	undef $cmd_id;
	undef $target_leafe;
}

sub eval_data { eval_cmd_data( keys %list ) }


sub _copy_values_of_nested_list {
	my $root_node = shift;                # source
	no strict;
	$target_leafe = shift;
	_parse_and_copy_node($root_node, '') if ref $root_node eq 'HASH';
}
sub _parse_and_copy_node {
	my ($parent_node, $parent_id) = @_;
	no strict;
	for ( keys %$parent_node ){
		$cmd_id = $parent_id . $_;
		$leaf_type = ref $parent_node->{$_};
		if (not $leaf_type) {
			$list{$cmd_id}{$target_leafe} = $parent_node->{$_}
				if $parent_node->{$_};
		} elsif ($leaf_type eq 'HASH'){
			_parse_and_copy_node($parent_node->{$_}, $cmd_id . '-')
		}
	}
}


sub numify_key_code {
	my @cmd = @_;
	my ($item_data, $rest, $kcode, $kname, $i, $char); #rawdata, keycode
	my $k18n = Kephra::Config::Localisation::strings()->{key};
	my $shift = $k18n->{meta}{shift}. '+';
	my $alt   = $k18n->{meta}{alt}  . '+';
	my $ctrl  = $k18n->{meta}{ctrl} . '+';
	my %keycode_map = (
		back => WXK_BACK, tab => WXK_TAB, enter => WXK_RETURN, esc => WXK_ESCAPE,
		space => WXK_SPACE, plus => 43, '#' => 47, tilde => 92, 
		del=> WXK_DELETE, ins => WXK_INSERT,
		pgup => WXK_PAGEUP, pgdn => WXK_PAGEDOWN, home => WXK_HOME, end => WXK_END,
		left => WXK_LEFT, up => WXK_UP, right => WXK_RIGHT, down => WXK_DOWN,
		f1 => WXK_F1, f2 => WXK_F2, f3 => WXK_F3, f4 => WXK_F4,  f5 => WXK_F5,  f6 => WXK_F6,
		f7 => WXK_F7, f8 => WXK_F8, f9 => WXK_F9,f10 => WXK_F10,f11 => WXK_F11,f12 => WXK_F12,
		numpad_enter => WXK_NUMPAD_ENTER
	);
	for (@cmd){
		$item_data = $list{$_};
		next unless exists $item_data->{key};
		$rest = $item_data->{key};
		$kname = '';
		$kcode = 0;
		while (){
			$i = index $rest, '+';
			last unless  $i > 0;
			$char = lc substr $rest, 0, 1;
			if    ($char eq 's') {$kname .= $shift; $kcode += 1000}
			elsif ($char eq 'c') {$kname .= $ctrl;  $kcode += 2000}
			elsif ($char eq 'a') {$kname .= $alt;   $kcode += 4000}
			$rest = substr $rest, $i + 1;
		}
		$kname .= exists $k18n->{$rest}
			? $k18n->{$rest}
			: ucfirst $rest;
		$item_data->{key} = $kname;
		$kcode += length($rest) == 1
			? ord uc $rest
			: $keycode_map{$rest};
		$item_data->{keycode} = $kcode;
	}
}

sub eval_cmd_data {
	my @cmd = @_;
	my $keymap = \@{$Kephra::app{editpanel}{keymap}};
	#Kephra::Config::existing_dirpath( $Kephra::config{app}{iconset_path} );
	my ($item_data, $ico_path);
	for (@cmd){
		my $item_data = $list{$_};
		for my $node_type (qw(call state enable)) {
			$item_data->{$node_type} = eval 'sub {'.$item_data->{$node_type}.'}'
				if $item_data->{$node_type};
		}
		if ($item_data->{call} and $item_data->{key}){
			$keymap->[$item_data->{keycode}] = $item_data->{call};
		}
		next unless $item_data->{icon};
		$item_data->{icon} = Kephra::Config::icon_bitmap($item_data->{icon});
	}
}


########################################
# external API - getting cmd date, manipulating content
########################################

sub new_cmd { replace_cmd(@_) unless exists $list{ $_[0] } }
sub new_cmd_list {
	for (@_) {
		#new_cmd();
	}
}
sub replace_cmd {
	my ($cmd_id, $properties) = @_;
	return unless ref $properties eq 'HASH';
	# if node exist, copy juste assigned values
	if ( exists $list{$cmd_id}) {
		$list{$cmd_id}{$_} = $properties->{$_} for keys %$properties;
	}
	else { $list{$cmd_id} = $properties }
	numify_key_code($cmd_id);
	eval_cmd_data($cmd_id);
}

sub del_cmd { delete @list{$_[0]} }

sub rename_ID {
	my ($old_ID, $new_ID) = @_;
	return unless $new_ID and ref $list{$old_ID} eq 'HASH';
	$list{$new_ID} = $list{$old_ID};
	del_cmd($old_ID);
}
# explicit value of one command
sub get_cmd_property {
	my $cmd_id = shift;
	my $leafe = shift;
	$list{$cmd_id}{$leafe}
		if ref $list{$cmd_id} eq 'HASH'
		and exists $list{$cmd_id}{$leafe};
}
# all values of one command
sub get_cmd_properties {
	my $cmd_id = shift;
	$list{$cmd_id} if ref $list{$cmd_id} eq 'HASH';
}
# values of same type from different commands
sub get_property_list {
	my $property = shift;
	my @result;
	for (@_) {
		push @result, $list{$_}{$property} if exists $list{$_}{$property}
	}
	return @result;
}

sub run_cmd_by_id {
	my $cmd_id = shift;
	$list{$cmd_id}{call}() if ref $list{$cmd_id}{call} eq 'CODE';
}

sub run_cmd_by_keycode {
	my $keycode = shift;
	my $keymap = $Kephra::app{editpanel}{keymap};
	if (ref $keymap->[$keycode] eq 'CODE'){
		$keymap->[$keycode]();
		return 1;
	}
	return 0;
}

sub del_temp_data{
	my $l18n = Kephra::Config::Localisation::strings();
	delete $l18n->{commandlist} if exists $l18n->{commandlist};
	#delete $Kephra::localisation{key}
	#	if exists $l18n->{key};
}

1;
