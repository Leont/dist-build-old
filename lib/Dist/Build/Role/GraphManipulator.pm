package Dist::Build::Role::GraphManipulator;

use Moose::Role;

with 'Dist::Build::Role::Plugin';

requires qw/manipulate_graph command_plugins/;

1;

# ABSTRACT: A plugin role for graph manipulators
