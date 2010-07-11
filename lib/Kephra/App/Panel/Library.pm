package Kephra::App::Panel::Library;
use strict;
use warnings;

our $VERSION = '0.01';

sub _config { Kephra::API::settings()->{app}{panel}{lib}}

sub start{}

1;
