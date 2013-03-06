package Dist::Build::Info;

use Moo;
extends 'Build::Graph::Info';

has config => (
	is       => 'ro',
	required => 1,
);

has meta_info => (
	is       => 'ro',
	required => 1,
);

has _options => (
	is       => 'ro',
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

has verbose => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return $self->option('verbose');
	},
);

1;

# ABSTRACT: Node info
