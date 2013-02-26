package Dist::Build::Role::GraphManipulator;

use Moose::Role;

with 'Dist::Build::Role::Plugin';

requires qw/manipulate_graph command_plugins/;

sub graph {
	my $self = shift;
	return $self->builder->graph;
}

1;

# ABSTRACT: A plugin role for graph manipulators
