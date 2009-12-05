package Kephra::API;
our $VERSION = '0.01';

=head1 NAME

Kephra::API - Interface between Modules and Plugins

=head1 DESCRIPTION

=cut
use strict;
use warnings;

sub settings     { Kephra::Config::Global::settings()      }
sub localisation { Kephra::Config::Localisation::strings() }
sub commands     { Kephra::CommandList::data()  }
sub events       { Kephra::EventTable::_table() }
sub menu         { Kephra::Menu::_all()    }
sub toolbar      { Kephra::ToolBar::_all() }

1;