package Kephra::API::CommandList;
$VERSION = '0.09';

################################################################################
# Commandlist = dynamic Structure, holding all internal calls with this info:  #
#             -ID -callback (str of subname) -icon* -label* -helptext*         #
#             starred data is optional                                         #
# These commands where used by different gui elements                          #
# names of commands contain underscore as separator                            #
################################################################################

use strict;
use Wx qw(
	WXK_ESCAPE WXK_BACK WXK_RETURN WXK_TAB WXK_SPACE
	WXK_DELETE WXK_INSERT WXK_HOME WXK_END
	WXK_UP WXK_DOWN WXK_LEFT WXK_RIGHT
	WXK_F1 WXK_F2 WXK_F3 WXK_F4 WXK_F5 WXK_F6 WXK_F7 WXK_F8 WXK_F9 WXK_F10 
	WXK_F11 WXK_F12
);

sub _get_config{ $Kephra::config{app}{commandlist} }
sub _get_data  { $Kephra::app{commandlist} }

sub load_cache{
}
sub store_cache {
	return unless _get_config()->{cache}{use};
	#my $config = _get_config();
	#my $file_name = $Kephra::temp{path}{config} . $config->{cache}{file};
	#Kephra::Config::File::store_yaml($file_name, _get_data());
}

sub load_data {
}

sub assemble_data {
	# get info from global configs and load commandlist conf file
	my $config       = _get_config();
	my $file_name    = Kephra::Config::filepath( $config->{file} );
	my $cmd_list_def = Kephra::Config::File::load($file_name);
	if ($config->{node} and exists $cmd_list_def->{ $config->{node} }) {
		$cmd_list_def = $cmd_list_def->{$config->{node}};
	} else { 
		return;
	}#
	# copy data of a hash structures into specified commandlist leafes
	foreach my $key ( qw{call enable enable_event state state_event key icon} ) {
		_copy_conf_values($cmd_list_def->{$key}, $key);
	}
	_copy_conf_values($Kephra::localisation{commandlist}{label},'label');
	_copy_conf_values($Kephra::localisation{commandlist}{help}, 'help');
	_create_keymap()
}

sub _copy_conf_values {
	no strict;
	my $root_node = shift;                # source
	local $target_leafe = shift;
	local ($leaf_type, $cmd_id);
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
	my $list = _get_data();
	my ($item_data, $rd, $kc, $kn, $i, $char); #rawdata, keycode
	my $shift = $Kephra::localisation{key}{meta}{shift} . '+';
	my $alt   = $Kephra::localisation{key}{meta}{alt}   . '+';
	my $ctrl  = $Kephra::localisation{key}{meta}{ctrl}  . '+';
	my %keycode_map = (
		back => WXK_BACK, tab => WXK_TAB, enter => WXK_RETURN, esc => WXK_ESCAPE, 
		space => WXK_SPACE, '#' => 47, tilde => 92, 
		del=> WXK_DELETE, ins => WXK_INSERT,
		pgup => 312, pgdn => 313, home => WXK_HOME, end => WXK_END, 
		left => WXK_LEFT, up => WXK_UP, right => WXK_RIGHT, down => WXK_DOWN,
		f1 => WXK_F1, f2 => WXK_F2, f3 => WXK_F3, f4 => WXK_F4,  f5 => WXK_F5,
		f6 => WXK_F6, f7 => WXK_F7, f8 => WXK_F8, f9 => WXK_F9, f10 => WXK_F10,
		f11 => WXK_F11, f12 => WXK_F12,
		numpad_enter => 372
	);
	for (keys %$list){
		$item_data = $list->{$_};
		if (exists $item_data->{key}){
			$rd = $item_data->{key};
			$kn = '';
			$kc = 0;
			while (){
				$i = index $rd, '+';
				last unless  $i > 0;
				$char = lc substr $rd, 0, 2;
				if    ($char eq 'sh') {$kn .= $shift; $kc += 1000}
				elsif ($char eq 'ct') {$kn .= $ctrl;  $kc += 2000}
				elsif ($char eq 'al') {$kn .= $alt;   $kc += 4000}
				$rd = substr $rd, $i + 1;
			}
			if (exists $Kephra::localisation{key}{$rd})
				{$kn .= $Kephra::localisation{key}{$rd}}
			else {$kn .= ucfirst $rd}
			$item_data->{label} .= "\t $kn "; # adding key name to label
			if (length ($rd)  == 1) { $kc += ord uc $rd } #
			else                    { $kc += $keycode_map{$rd} } #
			$item_data->{key} = $kc;
		}
	}
}

sub eval_data{
	my $list = _get_data();
	my $ico_dir = $Kephra::temp{path}{config}.$Kephra::config{app}{iconset_path};
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
}

sub get_cmd_properties{
	my $cmd_id = shift;
	my $list = _get_data();
	$list->{$cmd_id} if ref $list->{$cmd_id} eq 'HASH';
}

sub get_cmd_property{
	my $cmd_id = shift;
	my $leafe = shift;
	my $list = _get_data();
	$list->{$cmd_id}{$leafe}
		if ref $list->{$cmd_id} eq 'HASH'
		and exists $list->{$cmd_id}{$leafe};
}

sub run_cmd {
	my $cmd_id = shift;
	my $list = _get_data();
	&$list->{$cmd_id}{call} if ref $list->{$cmd_id}{call} eq 'CODE';
}

sub del_temp_data{
	delete $Kephra::localisation{commandlist}
		if exists $Kephra::localisation{commandlist};
}

#(stat $dateiname)[9]

1;
