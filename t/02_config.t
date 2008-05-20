#!/usr/bin/perl -w

# Test various miscellaneous configurationh functions

use strict;
BEGIN {
	$| = 1;
	push @INC, 'lib';
}

use Test::More tests => 18 + 7 + 1;
use Test::NoWarnings;

use Data::Dumper qw(Dumper);
use Kephra;





#####################################################################
# Kephra::Config::color

sub is_color {
	my ($it, $r, $g, $b, $name) = @_;
	isa_ok( $it, 'Wx::Colour' );
	is( $it->Red,   $r, "$name: ->Red ok"   );
	is( $it->Green, $g, "$name: ->Green ok" );
	is( $it->Blue,  $b, "$name: ->Blue ok"  );
}

SCOPE: {
	my $black1 = Kephra::Config::color('000000');
	my $white1 = Kephra::Config::color('FFFFFF');
	my $black2 = Kephra::Config::color('0,0,0');
	my $white2 = Kephra::Config::color('255,255,255');
	is_color( $black1, 0, 0, 0, 'hex black' );
	is_color( $black2, 0, 0, 0, 'dec black' );
	is_color( $white1, 255, 255, 255, 'hex white' );
	is_color( $white2, 255, 255, 255, 'dec white' );

	# Check errors
	eval {
		Kephra::Config::color();
	};
	like( $@, qr/Color string is not defined/, 'Caught undef error' );
	eval {
		Kephra::Config::color('black');
	};
	like( $@, qr/Unknown color string/, 'Caught bad-string error' );
}





#####################################################################
# Kephra::Config::icon_bitmap

sub is_icon {
	my $it = shift;
	isa_ok( $it, 'Wx::Bitmap' );
}

SCOPE: {
	# Set the default icon path for testing purposes
	local $Kephra::config{app}->{iconset_path} = 'share/config/interface/icon/set/jenne';

# edit_delete find_previous find_next goto_last_edit find_start

	my @known_good = qw{
		};
	foreach my $name ( @known_good ) {
		# Create using the raw name
		my $icon1 = Kephra::Config::icon_bitmap( $name );
		is_icon( $icon1 );

		# Create using the .xpm name
		my $icon2 = Kephra::Config::icon_bitmap( $name . '.xpm' );
		is_icon( $icon2 );
	}
}

#####################################################################
# Kephra::Config::File

require_ok('Kephra::Config::File');
{
    my $ref = Kephra::Config::File::load_node('share/config/interface/commands.conf', 'commandlist');
    is( ref($ref), 'HASH', 'commandlist is HASH' );
}

{
    #is( Kephra::Config::File::_get_type('mainmenuyml'), 'yaml', 'type is yaml' );
    #is( Kephra::Config::File::_get_type('ymainmenuyml'), 'yaml', 'type is yaml' );
    is( Kephra::Config::File::_get_type('/home/foo/.kephra/config/interface/mainmenu.yml'), 'yaml', 'type is yaml' );
    is( Kephra::Config::File::_get_type('share/config/interface/mainmenu.yml'), 'yaml', 'type is yaml' );
}

{
    my $file_name = 'share/config/interface/mainmenu.yml';
    is( Kephra::Config::File::_get_type($file_name), 'yaml', 'type is yaml' );
    my $ref = Kephra::Config::File::load_node($file_name, 'full_menubar');
    is( ref($ref), 'ARRAY', 'full_menubar is ARRAY' );
    $Kephra::temp{path}{config} = 'share/config';
    my $menubar_def = Kephra::Config::File::load_from_config_node_data ( {
          'responsive' => 1,
          'file' => 'interface/mainmenu.yml',
          'node' => 'full_menubar'
        } );
    is( ref($menubar_def), 'ARRAY', 'full_menubar is ARRAY' );
}


exit(0);
