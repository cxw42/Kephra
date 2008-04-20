package Kephra::API::CommandList;
$VERSION = '0.11';

=head1

Kephra::API::CommandList - Kephra's external API for sub calls

 Commandlist = dynamic Structure, holding all internal calls with this info:
             -ID -callback (str of subname) -icon* -label* -helptext*
             starred data is optional
 These commands where used by different gui elements
 names of commands contain underscore as separator
=cut

use strict;
use Wx qw(
	WXK_ESCAPE WXK_BACK WXK_RETURN WXK_TAB WXK_SPACE
	WXK_DELETE WXK_INSERT WXK_HOME WXK_END WXK_PAGEUP WXK_PAGEDOWN
	WXK_UP WXK_DOWN WXK_LEFT WXK_RIGHT
	WXK_F1 WXK_F2 WXK_F3 WXK_F4 WXK_F5 WXK_F6 WXK_F7 WXK_F8 WXK_F9 WXK_F10
	WXK_F11 WXK_F12
);

sub _config { $Kephra::config{app}{commandlist} }
sub _data   { $Kephra::app{commandlist} }

sub load_cache {}
sub store_cache {
	return unless _config()->{cache}{use};
	#my $config = _get_config();
	#my $file_name = $Kephra::temp{path}{config} . $config->{cache}{file};
	#Kephra::Config::File::store_yaml($file_name, _data());
}


# refactor commandlist definition & localisation data into a format that can be
# evaled and used by gui parts
sub assemble_data {
	my $cmd_list_def = shift;
	no strict;
	local ($leaf_type, $cmd_id, $target_leafe);
	# copy data of a hash structures into specified commandlist leafes
	for my $key ( qw{call enable enable_event state state_event key icon} ) {
		_copy_conf_values($cmd_list_def->{$key}, $key);
	}
	_copy_conf_values($Kephra::localisation{commandlist}{label},'label');
	_copy_conf_values($Kephra::localisation{commandlist}{help}, 'help');
	_create_keymap();
	undef $leaf_type;
	undef $cmd_id;
	undef $target_leafe;
}

sub _copy_conf_values {
	my $root_node = shift;                # source
	no strict;
	$target_leafe = shift;
	local $list = \%{ $Kephra::app{commandlist} }; # commandlist data
	_parse_node($root_node, '') if ref $root_node eq 'HASH';
}

sub _parse_node{
	my $parent_node = shift;
	my $parent_id = shift;
	no strict;
	for ( keys %$parent_node ){
		$cmd_id = $parent_id . $_;
		$leaf_type = ref $parent_node->{$_};
		if (not $leaf_type) {
			$list->{$cmd_id}{$target_leafe} = $parent_node->{$_}
				if $parent_node->{$_};
		} elsif ($leaf_type eq 'HASH'){
			_parse_node($parent_node->{$_}, "$cmd_id-")
		}
	}
}

sub _create_keymap{
	my $list = _data();
	my ($item_data, $raw, $kcode, $kname, $i, $char); #rawdata, keycode
	my $shift = $Kephra::localisation{key}{meta}{shift} . '+';
	my $alt   = $Kephra::localisation{key}{meta}{alt}   . '+';
	my $ctrl  = $Kephra::localisation{key}{meta}{ctrl}  . '+';
	my %keycode_map = (
		back => WXK_BACK, tab => WXK_TAB, enter => WXK_RETURN, esc => WXK_ESCAPE,
		space => WXK_SPACE, '#' => 47, tilde => 92,
		del=> WXK_DELETE, ins => WXK_INSERT,
		pgup => WXK_PAGEUP, pgdn => WXK_PAGEDOWN, home => WXK_HOME, end => WXK_END,
		left => WXK_LEFT, up => WXK_UP, right => WXK_RIGHT, down => WXK_DOWN,
		f1 => WXK_F1, f2 => WXK_F2, f3 => WXK_F3, f4 => WXK_F4,  f5 => WXK_F5,
		f6 => WXK_F6, f7 => WXK_F7, f8 => WXK_F8, f9 => WXK_F9, f10 => WXK_F10,
		f11 => WXK_F11, f12 => WXK_F12,
		numpad_enter => 372
	);
	for (keys %$list){
		$item_data = $list->{$_};
		if (exists $item_data->{key}){
			$raw = $item_data->{key};
			$kname = '';
			$kcode = 0;
			while (){
				$i = index $raw, '+';
				last unless  $i > 0;
				$char = lc substr $raw, 0, 1;
				if    ($char eq 's') {$kname .= $shift; $kcode += 1000}
				elsif ($char eq 'c') {$kname .= $ctrl;  $kcode += 2000}
				elsif ($char eq 'a') {$kname .= $alt;   $kcode += 4000}
				$raw = substr $raw, $i + 1;
			}
			if (exists $Kephra::localisation{key}{$raw})
				{$kname .= $Kephra::localisation{key}{$raw}}
			else {$kname .= ucfirst $raw}
			$item_data->{label} .= "\t  '$kname'"; # adding key name to label
			if (length ($raw)  == 1) { $kcode += ord uc $raw } #
			else                     { $kcode += $keycode_map{$raw} } #
			$item_data->{key} = $kcode;
		}
	}
}

sub eval_data {
	my $list = _data();
	my $keymap = \@{$Kephra::app{editpanel}{keymap}};

	my ($item_data, $ico_path);
	for ( keys %$list ){
		my $item_data = $list->{$_};
		if ($item_data->{call}){
			if ($item_data->{key}){
				$keymap->[$item_data->{key}] = $item_data->{call} =
					eval 'sub {'.$item_data->{call}.'}';
			} else {
				$item_data->{call} = eval 'sub {'.$item_data->{call}.'}';
			}
		}
		$item_data->{enable} = eval 'sub {'.$item_data->{enable}.'}'
			if $item_data->{enable};
		$item_data->{state} = eval 'sub {'.$item_data->{state}.'}'
			if $item_data->{state};
		next unless $item_data->{icon};
		$item_data->{icon} = Kephra::Config::icon_bitmap($item_data->{icon});
	}
	#$Kephra::temp{icon}{empty} = Kephra::Config::icon_bitmap('empty.xpm');
}

#
# external API
#

sub get_cmd_properties {
	my $cmd_id = shift;
	my $list = _data();
	$list->{$cmd_id} if ref $list->{$cmd_id} eq 'HASH';
}

sub get_cmd_property {
	my $cmd_id = shift;
	my $leafe = shift;
	my $list = _data();
	$list->{$cmd_id}{$leafe}
		if ref $list->{$cmd_id} eq 'HASH'
		and exists $list->{$cmd_id}{$leafe};
}

sub run_cmd_by_id {
	my $cmd_id = shift;
	my $list = _data();
	&$list->{$cmd_id}{call} if ref $list->{$cmd_id}{call} eq 'CODE';
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
	delete $Kephra::localisation{commandlist}
		if exists $Kephra::localisation{commandlist};
}

#(stat $dateiname)[9]

1;
