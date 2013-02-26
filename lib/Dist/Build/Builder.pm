package Dist::Build::Builder;

use Moose;

use Build::Graph;
use Dist::Build::Role::Plugin;

has meta_info => (
	is       => 'ro',
	isa      => 'CPAN::Meta',
	required => 1,
);

has name => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->meta_info->name;
	},
);

has version => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->meta_info->version;
	},
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
	default  => sub { ExtUtils::Config->new },
);

sub run {
	my ($self, $name) = @_;
	return $self->graph->run($name, options => $self->options, config => $self->config, meta_info => $self->meta_info);
}

1;

# ABSTRACT: The actual module builder of Dist-Build
