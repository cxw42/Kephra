# See end of file for docs, -NI = not implemented or used, -DEP = depreciated
package Kephra;

use 5.006;
use strict;

our $NAME       = __PACKAGE__;     # name of entire application
our $VERSION    = '0.3.10.24';           # version of entire app
our $PATCHLEVEL = 0;               # has just stable versions
our $STANDALONE = '';              # starter flag for moveable installations
our $BENCHMARK;                    # flag for benchmark loggings
our @ISA        = 'Wx::App';       # $NAME is a wx application

# Configuration Phase
use Cwd;
use File::Find;
use File::Spec::Functions ':ALL';
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

use Kephra::Extension::Notepad;
use Kephra::Extension::Output;

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
use Kephra::Document::SyntaxMode;  # language specific settings
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
	my $dir = File::UserConfig->new(@_);
}

sub configdir {
	$_[0] and $_[0] eq $NAME and shift;
	File::UserConfig->configdir(@_);
}

# Wx App Events
sub OnInit { &Kephra::App::start }   # boot app: init core and load config files
sub quit   { &Kephra::App::exit  
}   # save files & settings as configured

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

=over 4

=item Main Goals

My ideal is a balance of:

=over 2

=item * low entrance / easy to use

=item * rich feature set (CPAN IDE)

=item * highly configurable / adaptable to personal preferences

=item * beauty / good integration on GUI, code and config level

=back

That sounds maybe generic but we go for the grail of editing, nothing lesser.

=item Name

Especially from the last item derives the name, which is old egyptian and means
something like heart. Because true beauty and a harmonic synchronisation of all
parts of the consciousness begins when your heart awakens. Some call that true
love. In egypt tradition this was symbolized with a rising sun (ra) and the
principle of this was pictured as a scarab beatle with wings. Thats also a 
nice metaphor for an editor through which we give birth to programs, before
they rise on their own.

=item Details

I believe that Kephra's agenda is very similar to Perl's. Its common wisdom
that freedom means not only happiness but also life works most effective in
freedom. So there should not only be more than one way to write a programm,
but also more than one way use an editor. You could:

=over 4

=item * select menu items

=item * make kombinations of keystrokes

=item * point and click your way with the mouse

=item * type short edit commands

=back

So the question should not be vi or emacs, but how to combine the different
strengths (command input field and optional emacs-like keymap possibilities).
Perl was also a combination of popular tools and concepts into a single
powerful language.

Though I don't want to just adopt what has proven to be mighty. There are a lot
of tools (especially in the graphical realm) that are still waiting to be
discovered or aren't widely known. In Perl we write and rewrite them faster
and much more dense than in C or Java. Some function that help me every day
a lot, I written were in very few lines.

But many good tools are already on CPAN and Kephra should just be the glue
and graphical layer to give you the possibilities of these module to your 
fingertips in that form you prefer. This helpes also to improve these modules,
when they have more users that can give the authors feedback. It motivates
the community, when we can use our own tools and the perl ecosystem does not
depend on outer software like eclipse, even if it's sometimes useful.

Perl's second slogan is "Keep easy things easy and make hard things possible".
To me it reads "Don't scare away the beginners and grow as you go". And like
Perl I want to handle the complex things with as least effort as possible.
From the beginning Kephra was a useful programm and will continue so.


=head2 Features

Beside all the basic stuff that you would expect I listed here some features
by category in main menu:

=item File

file sessions, recents, simple templates, open all of a dir, insert,
autosave by timer, save copy as, rename, close all other, detection if
file where changed elsewhere

=item Editing

unlimited undo with fast modes, replace (clipboard and selection),
line edit functions, move line/selection, indenting, block formating,
delete trailing space, comment, convert (case, space or indention)
rectangular selection with mouse and keyboard, auto- and braceindention

=item Navigation

bracenav, blocknav, doc spanning bookmarks, goto last edit, last doc, 
rich search, incremental search, searchbar and search dialog

=item Tools

run script (integrated output panel), notepad panel

=item Doc Property

syntax mode, tab use, tab width, EOL, write protection

=item View

all app parts and margins can be switched on and off, syntaxhighlighting
bracelight, ight margin, indention guide, caret line, line wrap, EOL marker,
visible whitespace, changeable font

=item Configs

config files to be opened through a menu: 
settings, all menus, commandID's, event binding, icon binding, key binding, 
localisation (translate just one file to transelate the app), syntaxmodes

and some help texts to be opened as normal files

=head1 ROADMAP

=head2 TODO

fix config install under linux and mac

fix test suite

=head2 Stable 0.4

main features: 

GUI abstraction layer, searchbar, output panel, config dialog, syntaxmodes

This release is about getting the editor liquid or highly configurable.
Its also about improvements in the user interface and of course the little
things we missed. And its about time that it will released so that can we 
can concentrate more on features for coding support.

=head2 Stable 0.5

Things like code folding, snippet lib, help integration, autocompletition 
and so on. wish that by the end of 0.4.n series will be the extention API stable.

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

=head1 COPYRIGHT AND LICENSE

This Copyright applies only to the "Kephra" Perl software distribution,
not the icons bundled within.

Copyright 2004 - 2008 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU GPL.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
