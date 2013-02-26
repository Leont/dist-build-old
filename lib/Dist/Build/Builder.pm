package Dist::Build::Builder;

use Moose;

use Build::Graph;
use Dist::Build::Role::Plugin;
use Carp;

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
	is      => 'ro',
	isa     => 'Build::Graph',
	default => sub { return Build::Graph->new(info_class => 'Dist::Build::Info') },
);

has plugins => (
	isa      => 'ArrayRef[Dist::Build::Role::Plugin]',
	traits   => ['Array'],
	init_arg => undef,
	default  => sub { [] },
	handles  => {
		plugins        => 'elements',
		add_plugin     => 'push',
		search_plugin  => 'first',
		search_plugins => 'grep',
	},
);

has finalized => (
	is       => 'ro',
	isa      => 'Bool',
	traits   => ['Bool'],
	default  => 0,
	init_arg => undef,
	handles  => { _finalize => 'set' },
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

before add_plugin => sub {
	my $self = shift;
	Carp::croak('Can\'t add plugin to finalized builder') if $self->finalized;
};

sub finalize {
	my $self = shift;
	return if $self->finalized;

	for my $commandset ($self->plugins_with(-Command)) {
		$commandset->configure_commands;
	}
	for my $grapher ($self->plugins_with(-GraphManipulator)) {
		$grapher->manipulate_graph;
	}
	return;
}

sub run {
	my ($self, $name) = @_;
	$self->finalize;
	return $self->graph->run($name, options => $self->options, config => $self->config, meta_info => $self->meta_info);
}

sub plugin_named {
	my ($self, $name) = @_;
	return $self->search_plugin(sub { $_->plugin_name eq $name });
}

sub plugins_with {
	my ($self, $role) = @_;

	$role =~ s/ ^ - /Dist::Build::Role::/x;
	return $self->search_plugins(sub { $_->does($role) });
}

1;

# ABSTRACT: The actual module builder of Dist-Build
