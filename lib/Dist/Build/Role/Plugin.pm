package Dist::Build::Role::Plugin;

use strict;
use warnings;

use parent qw/Build::Graph::Role::Plugin/;

sub manipulate_graph;

sub options {
	return;
}

#ABSTRACT: Plugin role for Dist::Build

1;
