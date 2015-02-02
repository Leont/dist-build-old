package Dist::Build::Plugin::Sanity;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin Build::Graph::Role::Manipulator Build::Graph::Role::CommandProvider/;

use Carp;
use File::Copy 'copy';

sub configure_commands {
	my ($self, $commandset) = @_;
	$commandset->add('Core',
		module => __PACKAGE__,
		commands => {
			'copy' => sub {
				my $info   = shift;
				my $source = $info->arguments->{source};
				copy($source, $info->name) or croak "Could not copy: $!";
				return;
			},
		},
	);
	return;
}

sub manipulate_graph {
	my ($self, $graph) = @_;
	$graph->add_phony('build');
	return;
}

1;

# ABSTRACT: Plugin implemented the bare neceseties of any module build process
