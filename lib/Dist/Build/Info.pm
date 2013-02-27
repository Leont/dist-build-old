package Dist::Build::Info;

use Moose;
extends 'Build::Graph::Info';

has config => (
	is       => 'ro',
	isa      => 'ExtUtils::Config',
	required => 1,
);

has meta_info => (
	is       => 'ro',
	isa      => 'CPAN::Meta',
	required => 1,
);

has _options => (
	is       => 'ro',
	isa      => 'HashRef',
	init_arg => 'options',
);

sub option {
	my ($self, $key) = @_;
	return $self->_options->{$key};
}

sub options {
	my $self = shift;
	return %{ $self->_options };
}

sub verbose {
	my $self = shift;
	return $self->option('verbose');
}

1;

# ABSTRACT: Node info
