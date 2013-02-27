package Dist::Build::Builder;

use Moose;

use Build::Graph;

has action => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has meta_info => (
	is       => 'ro',
	isa      => 'CPAN::Meta',
	required => 1,
);

has graph => (
	is       => 'ro',
	isa      => 'Build::Graph',
	required => 1,
);

has options => (
	is       => 'ro',
	isa      => 'HashRef',
	required => 1,
);

has config => (
	is       => 'ro',
	isa      => 'ExtUtils::Config',
	required => 1,
);

sub run {
	my $self = shift;
	return $self->graph->run($self->action, options => $self->options, config => $self->config, meta_info => $self->meta_info);
}

1;

# ABSTRACT: The actual module builder of Dist-Build
