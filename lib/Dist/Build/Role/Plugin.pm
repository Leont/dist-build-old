package Dist::Build::Role::Plugin;

use strict;
use warnings;

use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name => $args{name} || ($class =~ / \A (?:.*::)? ([^:]+) \z /xms)[0]
	}, $class;
	return $self;
}

sub commandsets {
	return;
}

sub manipulate_graph;

sub options {
	return;
}

sub meta_merge {
	return;
}

1;

#ABSTRACT: Plugin role for Dist::Build

=method run_command($name, @arguments)

Run the local command C<$name> with C<@arguments>.

=method run_trans($name, @arguments)

Run the local transformation C<$name> with C<@arguments>.

=method get_commands()

This should return a hash mapping local command names to a function.

=method get_trans()

This should return a hash mapping local transformation names to a function.

=method add_file($name, %options)

=method add_phony($name, %options)

=method add_variable($name, @values)

=method add_wildcard($name, %options)

=method add_subst($name, %options)

1;
