package Dist::Build::Role::Graph::Manipulator;

use Moose::Role;

with qw/Dist::Build::Role::Plugin Build::Graph::Role::Manipulator/;

1;

# ABSTRACT: A plugin role for graph manipulators