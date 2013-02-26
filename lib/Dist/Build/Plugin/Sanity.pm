package Dist::Build::Plugin::Sanity;

use Moose;
with qw/Dist::Build::Role::Plugin Dist::Build::Role::GraphManipulator/;

use Carp;
use File::Copy 'copy';

sub manipulate_graph {
	my $self = shift;
	my $graph = $self->builder->graph;

	$graph->add_phony('build');
	$graph->commands->add('copy', sub {
		my $info = shift;
		my ($source) = $info->dependencies->with_type('source');
		copy($source, $info->name) or croak "Could not copy: $!";
		return;
	});

	$self->builder->connect_node('build', check => [ [ qw/build requires/ ] ], warn => [ [ qw/build recommends/ ] ]);
	return;
}

1;

__END__

# ABSTRACT: Plugin implemented the bare neceseties of any module build process
