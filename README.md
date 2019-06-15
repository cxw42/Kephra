# NAME

Kephra - crossplatform GUI-Texteditor along Perl alike Paradigms 

# SYNOPSIS

        > kephra [<files>]   # start with files already open

# DESCRIPTION

This module install's a complete editor application with all its configs
and documentation for your programming, web and text authoring. 

## Philosophy

- Main Goals

    A visually harmonic and beautiful, sparing and elegantly programed Editor,
    that helpes you with all your daily tasks. It should be also able to operate
    in the way you prefer and be not afraid to try new things.

- In Depth

    I know, I know, there are plenty text editors out there, even some really
    mighty IDE, but still no perfect solution for many programmers. So lets

    >     learn from Perl what it takes to build a tool thats powerful and fun to
    >     play with for hours and months.
    >
    >     \* make a low entry barrier (usable like notepad)
    >
    >     \* copy what people like and are used to and whats not inherently broken
    >
    >     \* give choices (TimTowtdi) 
    >
    >     - (e.g. deliver vi and emacs input style)
    >     - usable with menu, contextmenu, bars, mouse combo, key combos, commands ...
    >     - configure via dialog and yaml/conf files ...
    >
    >     \* highly configurable / adaptable to personal preferences
    >
    >     \* beauty / good integration on GUI, code and config level
    >
    >     \* solve things with minimal effort (no bloat / minimal dependencies)
    >
    >     \* still everything extendable by easy to write plugins

        I believe strongly that there is much more possible with GUI editors
        and text editors in general than we are used today. So I try to weave
        fresh ideas wherever I can and design Kephra in a way, that every 
        programmer can alter and extend it easily. That can speed up progress
        or at least makes Kephra more comfortable for you.

        That is the plan, but we are currently not nearly that far.

- Name

    Especially from the last item derives the name, which is old egyptian and means
    something like heart. Because true beauty and a harmonic synchronisation of all
    parts of the consciousness begins when your heart awakens. Some call that true
    love. In egypt tradition this was symbolized with a rising sun (ra) and the
    principle of this was pictured as a scarab beatle with wings. Thats also a 
    nice metaphor for an editor through which we give birth to programs, before
    they rise on their own.

- Details

    I believe that Kephra's agenda is very similar to Perl's. Its common wisdom
    that freedom means not only happiness but also life works most effective in
    freedom. So there should not only be more than one way to write a program,
    but also more than one way use an editor. You could:

    - select menu items
    - make kombinations of keystrokes
    - point and click your way with the mouse
    - type short edit commands

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
From the beginning Kephra was a useful program and will continue so.

## Features

Beside all the basic stuff that you would expect I listed here some features
by category in main menu:

- File

    file sessions, history, simple templates, open all of a dir, insert,
    autosave by timer, save copy as, rename, close all other, detection if
    file where changed elsewhere

- Editing

    unlimited undo with fast modes, replace (clipboard and selection),
    line edit functions, move line/selection, indenting, block formating,
    delete trailing space, comment, convert (case, space or indention)
    rectangular selection with mouse and keyboard, auto- and braceindention

- Navigation

    bracenav, blocknav, doc spanning bookmarks, goto last edit, last doc, 
    rich search, incremental search, searchbar and search dialog

- Tools

    run script (integrated output panel), notepad panel, color picker

- Doc Property

    syntax mode, codepage, tab use, tab width, EOL, write protection

- View

    all app parts and margins can be switched on and off, syntaxhighlighting
    bracelight, ight margin, indention guide, caret line, line wrap, EOL marker,
    visible whitespace, changeable font

- Configs

    config files to be opened through a menu: 
    settings, all menus, commandID's, event binding, icon binding, key binding, 
    localisation (translate just one file to transelate the app), syntaxmodes

    and some help texts to be opened as normal files

# ROADMAP

## Overview

Enduser Release 0.1

    a very simple editor
    

Enduser Release 0.2

    multiple documents, file session
    

Enduser Release 0.3

    searchbar and more comfort

Enduser Release 0.4

    This release was about getting the editor liquid or highly configurable.
    Its also about improvements in the user interface and of course the little
    things we missed. It also contains interpreter output panel and a notepad.

Enduser Release 0.5

    This release is about getting Kephra into the 'real' world out there
    and adding feature that are most needed and removing most hindering barriers.
    Folding, encodings, printing, .... and lot of minor tools and more help.

Enduser Release 0.6

    This release will be about extending Kephra internal extensions like a 
    file brwoser, command line and tree lib as Plugin API.

Enduser Release 0.7

     Introducing Syntaxmodes, for language sensitive data and functionions.

Enduser Release 0.8

    more heavier stuff like debugger

## This Cycle

- Testing 0.4.1 - code folding
- Testing 0.4.2 - folding and GUI refined, movable tabs, 2 more tools, doc data
- Testing 0.4.3 - utf, marker, folding finished, 3 more tools, help links
- Testing 0.4.4 - new mouse control, 2 more tools, updated docs
- Testing 0.4.5 - more encodings, local notepad
- Testing 0.4.6 - config dialog
- Stable 0.5 - about dialog

# SUPPORT

Bugs should be reported via the CPAN bug tracker at

[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kephra](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kephra)

For other issues, contact the author.

More info and resources you find on our sourceforge web page under:

[http://kephra.sourceforge.net](http://kephra.sourceforge.net)

# ACKNOWLEDGMENTS

- Herbert Breunung <lichtkind@cpan.org> (main author)
- Jens Neuwerk (author of icons, GUI advisor)
- Andreas Kaschner (linux and mac ports)
- Adam Kennedy <adamk@cpan.org> (cpanification)
- Renee Bäcker <module@renee-baecker.de> (color picker)
- Fabrizio Regalli &lt;fabreg@fabreg.it&lt;gt> (typos)
- many more since we study other editors a lot and also the padre sources

# COPYRIGHT AND LICENSE

This Copyright applies only to the "Kephra" Perl software distribution,
not the icons bundled within.

Copyright 2004 - 2010 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU GPL.

The full text of the license can be found in the LICENSE file included
with this module.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 222:

    You can't have =items (as at line 228) unless the first thing after the =over is an =item

- Around line 451:

    Non-ASCII character seen before =encoding in 'Bäcker'. Assuming UTF-8
