package Dist::Build::Plugin::Sanity;

use Moo;
with qw/Dist::Build::Role::Graph::CommandProvider Dist::Build::Role::Graph::Manipulator/;

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
