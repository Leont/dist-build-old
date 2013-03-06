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

has verbose => (
	is      => 'ro',
	default => sub {
		my $self = shift;
		return $self->option('verbose');
	},
);

has install_paths => (
	is => 'lazy',
	default => sub {
		my $self = shift;
		require ExtUtils::InstallPaths;
		return ExtUtils::InstallPaths->new(%{ $self->_options }, config => $self->config, dist_name => $self->meta_info->name);
	},
);

1;

# ABSTRACT: Node info
