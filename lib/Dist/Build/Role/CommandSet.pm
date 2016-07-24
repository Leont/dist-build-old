package Dist::Build::Role::CommandSet;

use base 'Build::Graph::Role::CommandSet';

sub get_action {
	my ($self, $name) = @_;
	return $self->get_actions($self->{graph})->{$name} || Carp::croak("No such command $name in $self->{name}");
}

sub get_actions {
	return {};
}

sub get_transformation {
	my ($self, $name) = @_;
	return $self->get_trans($self->{graph})->{$name} || Carp::croak("No such transformation $name in $self->{name}");
}

sub get_trans {
	return {};
}

1;

