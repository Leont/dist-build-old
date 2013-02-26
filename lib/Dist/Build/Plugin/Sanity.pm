package Dist::Build::Plugin::Sanity;

use Moose;
with qw/Dist::Build::Role::Plugin Dist::Build::Role::Command Dist::Build::Role::GraphManipulator/;

use Carp;
use File::Copy 'copy';

sub configure_commands {
	my $self = shift;
	$self->graph->commands->add('copy', sub {
		my $info = shift;
		my $source = $info->arguments->{source};
		copy($source, $info->name) or croak "Could not copy: $!";
		return;
	});
	return;
}

sub manipulate_graph {
	my $self = shift;
	$self->graph->add_phony('build');

	$self->builder->connect_node('build', check => [ [ qw/build requires/ ] ], warn => [ [ qw/build recommends/ ] ]);
	return;
}

1;

# ABSTRACT: Plugin implemented the bare neceseties of any module build process
