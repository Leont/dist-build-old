package Dist::Build::Role::Plugin;

use strict;
use warnings;

use base qw/Build::Graph::Role::Plugin/;

use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	Scalar::Util::weaken($self->{graph} = $args{graph} || Carp::croak('No graph given'));
	return $self;
}

sub manipulate_graph;

sub get_command {
	my ($self, $name) = @_;
	return $self->get_commands->{$name} || Carp::croak("No such command $name in $self->{name}");
}

sub get_commands {
	return {};
}

sub get_transformation {
	my ($self, $name) = @_;
	return $self->get_trans->{$name} || Carp::croak("No such transformation $name in $self->{name}");
}

sub get_trans {
	return {};
}

sub run_command {
	my ($self, $command, @arguments) = @_;
	my ($plugin, $subcommand) = $command =~ m{ ^ ([^/]+) / (.*) }x ? ($self->{graph}->lookup_plugin($1), $2) : ($self, $command);
	return $plugin->get_command($subcommand)->(@arguments);
}

sub run_trans {
	my ($self, $trans, @arguments) = @_;
	my ($plugin, $subtrans) = $trans =~ m{ ^ ([^/]+) / (.*) }x ? ($self->{graph}->lookup_plugin($1), $2) : ($self, $trans);
	return $plugin->get_transformation($subtrans)->(@arguments);
}

sub _rel_to_abs {
	my ($value, $pwd) = @_;
	return $value if not defined $value or not @{$value} or $value->[0] =~ m{/};
	return [ "$pwd/" . $value->[0], @{$value}[ 1..$#{ $value } ] ];
}

for my $method (qw/add_file add_phony/) {
	no strict 'refs';
	*{$method} = sub {
		my ($self, $name, %options) = @_;
		$options{action} = _rel_to_abs($options{action}, $self->{name});
		return $self->{graph}->$method($name, %options);
	};
}

for my $method (qw/add_variable add_wildcard/) {
	no strict 'refs';
	*{$method} = sub {
		my ($self, $name, @arguments) = @_;
		return $self->{graph}->$method($name, @arguments);
	};
}

sub add_subst {
	my ($self, $sink, $source, %options) = @_;
	$options{trans}  = _rel_to_abs($options{trans}, $self->{name});
	$options{action} = _rel_to_abs($options{action}, $self->{name});
	return $self->{graph}->add_subst($sink, $source, %options);
}

sub options {
	return;
}

sub meta_merge {
	return;
}

sub to_hashref {
	my $self = shift;
	my $ret = $self->SUPER::to_hashref;
	$ret->{name} = $self->{name};
	return $ret;
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
