package Dist::Build::Info;

use strict;
use warnings;

use parent 'Build::Graph::Info';

use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{config} = $args{config} || Carp::croak('No config is given');
	$self->{meta} = $args{meta} || Carp::croak('No meta is given');
	$self->{options} = $args{options} || {};
	$self->{install_paths} = $args{install_paths} if $args{install_paths};
	return $self;
}

sub config {
	my $self = shift;
	return $self->{config};
}

sub meta {
	my $self = shift;
	return $self->{meta};
}

sub option {
	my ($self, $key) = @_;
	return $self->{options}{$key};
}

sub verbose {
	my $self = shift;
	return $self->option('verbose');
}

sub install_paths {
	my $self = shift;
	return $self->{install_paths} ||= do {
		require ExtUtils::InstallPaths;
		return ExtUtils::InstallPaths->new(%{ $self->_options }, config => $self->config, dist_name => $self->meta_info->name);
	};
}

1;

# ABSTRACT: Node info
