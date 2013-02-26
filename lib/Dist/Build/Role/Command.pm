package Dist::Build::Role::Command;

use Moose::Role;

with 'Dist::Build::Role::Plugin';

requires 'configure_commands';

sub command_plugins {
	my $self = shift;
	return ref $self;
}

1;

# ABSTRACT: A plugin role for graph manipulators

