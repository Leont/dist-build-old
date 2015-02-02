package Dist::Build::Role::Plugin;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless {
		name => $args{name} || Carp::croak('No name given'),
	}, $class;
}

sub name {
	my $self = shift;
	return $self->{name};
}

sub configure {
}

1;

# ABSTRACT: Plugin role
