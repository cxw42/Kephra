# See end of file for docs, -NI = not implemented or used, -DEP = depreciated

package Kephra;

use 5.006;
use strict;

our $NAME       = __PACKAGE__; # name of entire application
our $VERSION    = '0.3.8.2';   # version of entire app
our @ISA        = 'Wx::App';   # $NAME is a wx application

# Configuration Phase
use File::Spec::Functions ':ALL';
use File::HomeDir    ();
use File::UserConfig ();
use Config::General  ();
use YAML             ();

# Find the configuration directory
BEGIN {
	#$main::CONFIG = File::UserConfig->new(
		#dist   => 'Kephra',
		#module => 'Kephra',
	#)->configdir;

	# Set and check main directories
	#$Kephra::internal{path}{config} = catdir($main::CONFIG, 'config');
	#unless ( -d $Kephra::internal{path}{config} ) {
		#Carp::croak("Failed to locate main config path");
	#}
	#$Kephra::internal{path}{help} = catdir($main::CONFIG, 'help');
	#unless ( -d $Kephra::internal{path}{help} ) {
		#Carp::croak("Failed to locate help directory");
	#}
	#$Kephra::internal{path}{user} = File::HomeDir->my_home;
	#unless ( -d $Kephra::internal{path}{user} ) {
		#Carp::croak("Failed to locate user home directory");
	#}

	# set locations of boot files
	#$Kephra::internal{file}{config}{auto}      = catfile('global', 'autosaved.conf');
	#$Kephra::internal{file}{config}{default}   = catfile('global', 'default.conf');
	#$Kephra::internal{file}{img}{splashscreen} = catfile('icon', 'splash', 'wx_perl_splash.jpg');

	# Make module-style config files accessible
	#push @INC, $main::CONFIG;
}
 
sub user_config {
	$_[0] and $_[0] eq $NAME and shift;
	File::UserConfig->new(@_);
}

sub configdir {
	$_[0] and $_[0] eq $NAME and shift;
	File::UserConfig->configdir(@_);
}

use Wx;                         # Core wxWidgets Framework
use Wx::STC;                    # Scintilla editor component
use Wx::DND;                    # Drag'n Drop & Clipboard support (only K::File)
use Wx::Print;                  # Print Support (used only in Kephra::File )

# required external modules (loaded if needed in packages)
# require Hash::Merge;          # for config hash merging
# require Clone;                # Hash::Merge Dependency
# require Cwd;                  # for some Config::Settings
# require Text::Wrap            # for text formating
# require Perl::Tidy;           # -NI perl formating

# for adam                      # (use Scalar::Util 'weaken';)
#use PPI ();                    # For refactoring support
#use Params::Util ();           # Parameter checking
#use Class::Inspector ();       # Class checking

# used internal modules, parts of pce
use Kephra::API::CommandList;      # UI API
use Kephra::API::EventTable;       # internal app API
use Kephra::API::Extension;        # Plugin API
use Kephra::App;                   # App start&exit, namespace 4 wx related things
use Kephra::App::ContextMenu;      # contextmenu manager
use Kephra::App::EditPanel;        #
use Kephra::App::EditPanel::Margin;#
use Kephra::App::MainToolBar;      #
use Kephra::App::Menu;             # base menu builder
use Kephra::App::MenuBar;          # main menu
use Kephra::App::ToolBar;          # base toolbar builder
use Kephra::App::SearchBar;        # Toolbar for searching and navigation
use Kephra::App::StatusBar;        #
use Kephra::App::TabBar;           # API 2 Wx::Notebook, FileSelector
use Kephra::App::Window;           # API 2 Wx::Frame and more
use Kephra::Config;                # low level config manipulation
use Kephra::Config::File;          # API 2 ConfigParser: Config::General, YAML
use Kephra::Config::Global;        # API 4 config, general content level
use Kephra::Config::Interface;     #
use Kephra::Config::Tree;          #
use Kephra::Dialog;                # API 2 dialogs, submodules are loaded runtime
use Kephra::Document;              # document menu funktions
use Kephra::Document::Change;      # calls for changing current doc
use Kephra::Document::Internal;    # doc handling helper methods
use Kephra::Document::SyntaxMode;  # doc handling helper methods
use Kephra::Edit;                  # basic edit menu funktions
use Kephra::Edit::Comment;         # comment functions
use Kephra::Edit::Convert;         # convert functions
use Kephra::Edit::Format;          # formating functions
use Kephra::Edit::History;         # undo redo etc.
use Kephra::Edit::Goto;            # editpanel textcursor navigation
use Kephra::Edit::Search;          # search menu functions
use Kephra::Edit::Select;          # text selection
use Kephra::Edit::Bookmark;        # doc spanning bookmarks
use Kephra::File;                  # file menu functions
use Kephra::File::History;         # list of recent used Files
use Kephra::File::IO;              # API 2 FS, read write files
use Kephra::File::Session;         # file session handling
use Kephra::Module;                # Module Handling
use Kephra::Show;                  # -DEP display content: files, boxes

# internal modules / loaded when needed
#require Kephra::Config::Embedded; # build in emergency settings
#require Kephra::Dialog::Config;   # config dialog
#require Kephra::Dialog::Exit;     # select files to be saved while exit program
#require Kephra::Dialog::Info;     # info box
#require Kephra::Dialog::Keymap;   #
#require Kephra::Dialog::Notify    # inform about filechanges from outside
#require Kephra::Dialog::Search;   # find and replace dialog

# global data
our %app;           # ref to app parts and app data for GUI, Events, Parser
our %config;        # global settings, saved in /config/global/autosaved.conf
our %document;      # data of current documents, to be stored in session file
our %help;          # -NI locations of documentation files in current language
our %temp;          # global internal temp data
our %localisation;  # all localisation strings in your currently selected lang
our %syntaxmode;    # -NI


# Wx App Events
sub OnInit { &Kephra::App::start }   # boot app: init core and load config files
sub quit   { &Kephra::App::exit  }   # save files & settings as configured

1;

__END__

=head1 NAME

Kephra.pm - Kephra Base Module

for main Docs please go to L<kephra> 

=head1 Purpose
