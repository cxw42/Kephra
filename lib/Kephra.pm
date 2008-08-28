# See end of file for docs, -NI = not implemented or used, -DEP = depreciated
package Kephra;

use 5.006;
use strict;

our $NAME       = __PACKAGE__;     # name of entire application
our $VERSION    = '0.3.9.15';      # version of entire app
our $PATCHLEVEL;                   # has just stable versions
our $STANDALONE = '';              # starter flag for moveable installations
our $BENCHMARK;                    #
our @ISA        = 'Wx::App';       # $NAME is a wx application

# Configuration Phase
use Cwd;
use File::Spec::Functions ':ALL';
use File::HomeDir    ();
use File::UserConfig ();
use Config::General  ();
use YAML::Tiny       ();

use Wx;                            # Core wxWidgets Framework
use Wx::STC;                       # Scintilla editor component
use Wx::DND;                       # Drag'n Drop & Clipboard support (only K::File)
#use Wx::Print;                    # Printing Support (used only in Kephra::File )
#use Text::Wrap                    # for text formating

# these will used in near future
#use Perl::Tidy;                   # -NI perl formating
#use PPI ();                       # For refactoring support
#use Params::Util ();              # Parameter checking
#use Class::Inspector ();          # Class checking

use Kephra::Extention::Notepad;
use Kephra::Extention::Output;

# used internal modules, parts of kephra
use Kephra::API::CommandList;      # UI API
use Kephra::API::EventTable;       # internal app API
use Kephra::API::Extension;        # Plugin API
use Kephra::API::Panel;            #
use Kephra::App;                   # App start & shut down sequence
use Kephra::App::ContextMenu;      # contextmenu manager
use Kephra::App::EditPanel;        #
use Kephra::App::EditPanel::Margin;#
use Kephra::App::MainToolBar;      #
use Kephra::App::Menu;             # base menu builder
use Kephra::App::MenuBar;          # main menu
use Kephra::App::ToolBar;          # base toolbar builder
use Kephra::App::SearchBar;        # Toolbar for searching and navigation
use Kephra::App::StatusBar;        #
use Kephra::App::TabBar;           # API 2 Wx::Notebook
use Kephra::App::Window;           # API 2 Wx::Frame and more
use Kephra::Config;                # low level config manipulation
use Kephra::Config::Default;       # build in emergency settings
#use Kephra::Config::Default::CommandList;
#use Kephra::Config::Default::ContextMenus;
#use Kephra::Config::Default::GlobalSettings;
#use Kephra::Config::Default::Localisation;
#use Kephra::Config::Default::MainMenu;
#use Kephra::Config::Default::ToolBars;
use Kephra::Config::File;          # API 2 ConfigParser: Config::General, YAML
use Kephra::Config::Global;        # API 4 config, general content level
use Kephra::Config::Interface;     #
use Kephra::Config::Tree;          #
use Kephra::Dialog;                # API 2 dialogs, fileselectors, msgboxes
#use Kephra::Dialog::Config;       # config dialog
#use Kephra::Dialog::Exit;         # select files to be saved while exit program
#use Kephra::Dialog::Info;         # info box
#use Kephra::Dialog::Keymap;       #
#use Kephra::Dialog::Notify        # inform about filechanges from outside
#use Kephra::Dialog::Search;       # find and replace dialog
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
use Kephra::Show;                  # -DEP display content: files

# global data
our %app;           # ref to app parts and app data for GUI, Events, Parser
our %config;        # global settings, saved in /config/global/autosaved.conf
our %document;      # data of current documents, to be stored in session file
our %help;          # -NI locations of documentation files in current language
our %temp;          # global internal temp data
our %localisation;  # all localisation strings in your currently selected lang
our %syntaxmode;    # -NI

sub user_config {
	$_[0] and $_[0] eq $NAME and shift;
	File::UserConfig->new(@_);
}

sub configdir {
	$_[0] and $_[0] eq $NAME and shift;
	File::UserConfig->configdir(@_);
}

# Wx App Events
sub OnInit { &Kephra::App::start }   # boot app: init core and load config files
sub quit   { &Kephra::App::exit  }   # save files & settings as configured

1;

__END__

=head1 NAME

Kephra - crossplatform, GUI-Texteditor along perllike Paradigms 

=head1 SYNOPSIS

    > kephra [<files>]   # start with certain files open

=head1 DESCRIPTION

This module install's a complete editor application with all its configs
and documentation for your programming, web and text authoring. 

=head2 Philosophy

I know, I know, there are plenty text editors out there, even some really
mighty IDEs, but still no perfect solution for many Programmers. So lets
learn from Perl what it takes to build a tool thats powerful and fun to
play with for hours and months.

=over 4

=item *  make a low entry barrier

=item *  copy what people like and are used to

=item *  give choices (TMTOWDI) 

=over 2

=item * usable with mouse and keyboard commands and menus 

=item * deliver vi (commandline) and emacs (complex keybinding) input style

=item * configure via dialog and yaml/conf files ...

=item * much more ...

=back

=item * but keep an eye on the overall, that all fits together nicely

=back

Furthermore I made some design decisions that should define Kephra:

=over 4

=item * beautiful, well crafted GUI with own Icons

=item * most features are optional / configurable

=item * easy extendable with our beloved perl

=item * solve things with minimal effort (no bloat / minimal dependencies)

=item * turn CPAN into a IDE and provide just the glue

=back

I believe strongly that there is much more possible with GUI editors
and text editors in general than we are used today. So I try to design
Kephra in a way, that every programmer can alter and extend it easily.
That can speed up progress or at least makes Kephra more comfortable 
for you.

That is the plan, but we are currently not nearly that far.

=head2 Features

Beside all the basic stuff that you would expect from a notepad, we have
file sessions, simple templates, recent closed files, and file functions
applied to all files, where it makes sense.

We have also a pile of advanced text navigation (on braces or blockwise),
goto last edit or 10 doc spanning Bookmarks as well as find in files. 

Advanced undo, line editing (edit functions that take the current line as
input), move selected text by mouse or keyboard. Formating funtions like 
blockformat, align blocks, indenting, commenting ...

Documents have several properties like syntax styling, auto indention, tab
width, tab use, write protection.

View options contain switches for any GUI element and marker for: current
line, end of line bytes, right margin, indetion guides, bracehiglighting,
line wrap and font.

Every menu and toolbar is evaluated from a simple yaml file, so you can 
change it easily by opening this files from the config menu.

=head1 ROADMAP

=head2 Stable Release 0.4

This release is about getting the editor liquid or highly configurable.
Its also about improvements in the user interface and of course the little
things we missed. And its about time that it will released so that can we 
can concentrate more on features for coding support.

=head2 Stable Release 0.5

Things like output panel, code folding, snippet lib, help integration,
autocompletition and so on. Hope that by the end of 0.4.n series will be
the extention API stable.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kephra>

For other issues, contact the author.

More info and resources you find on our sourceforge web page under:

L<http://kephra.sourceforge.net>

=head1 AUTHORS

=item * Herbert Breunung E<lt>lichtkind@cpan.orgE<gt> (main author)

=item * Jens Neuwerk E<lt>jenne@gmxpro.netE<gt> (author of icons, GUI advisor)

=item * Adam Kennedy E<lt>adamk@cpan.orgE<gt> (cpanification)

=item * Gábor Szabó E<lt>szabgab@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This Copyright applies only to the "Kephra" Perl software distribution,
not the icons bundled within.

Copyright 2004 - 2008 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU GPL.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
