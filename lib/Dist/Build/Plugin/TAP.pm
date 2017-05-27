package Dist::Build::Plugin::TAP;

use strict;
use warnings;

use base qw/Dist::Build::Role::Plugin/;

use Carp;
use File::Spec::Functions qw/catdir rel2abs/;

sub manipulate_graph {
	my ($self, $graph) = @_;
	$graph->add_pattern('test-files', dir => 't', pattern => '*.t');
	$graph->add_phony('test',
		action       => [ 'tap-harness', '%{verbose,jobs}', '@test-files' ],
		dependencies => [ 'build', '@test-files' ]
	);
	return;
}

1;

# ABSTRACT: A TAP consuming testing plugin

