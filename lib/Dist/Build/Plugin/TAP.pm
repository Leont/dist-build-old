package Dist::Build::Plugin::TAP;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin Build::Graph::Role::Manipulator Build::Graph::Role::CommandProvider/;

use Carp;
use File::Spec::Functions qw/catdir rel2abs/;
use TAP::Harness;

sub configure_commands {
	my ($self, $commandset) = @_;
	$commandset->add('TAP',
		module => __PACKAGE__,
		commands => {
			'tap-harness' => sub {
				my $info    = shift;
				my $tester  = TAP::Harness->new({ verbosity => $info->verbose, lib => rel2abs(catdir(qw/blib lib/)), color => -t STDOUT });
				my @files = $info->graph->get_named('test-files');

				my $results = $tester->runtests(@files);
				croak "Errors in testing.  Cannot continue.\n" if $results->has_errors;
			},
		},
	);
	return;
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	$graph->add_phony('testbuild', dependencies => [ 'build' ]);
	$graph->add_wildcard(dir => 't', pattern => '*.t', name => 'test-files', dependents => 'testbuild');
	$graph->add_phony('test', action => [ 'TAP/tap-harness' ], dependencies => [ 'testbuild' ]);
	return;
}

1;

# ABSTRACT: A TAP consuming testing plugin

