package Dist::Build::Role::CommandSet;

use strict;
use warnings;
use base 'Build::Graph::Role::CommandSet';

sub get_action {
	my ($self, $name, @arguments) = @_;
	my $action = $self->get_actions($self->{graph})->{$name};
	Carp::croak("No such command $name in $self->{name}") if not $action;
	return sub { $action->(@arguments) };
}

sub get_actions {
	return {};
}

sub get_transformation {
	my ($self, $name, @arguments) = @_;
	my $trans = $self->get_trans($self->{graph})->{$name};
	Carp::croak("No such transformation $name in $self->{name}") if not $trans;
	return sub { $trans->(@arguments) };
}

sub get_trans {
	return {};
}

1;

