package Dist::Build::Plugin::TAP;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin Build::Graph::Role::Manipulator Build::Graph::Role::CommandProvider/;

use Carp;
use File::Spec::Functions qw/catdir rel2abs/;

sub configure_commands {
	my ($self, $commandset) = @_;
	$commandset->add('TAP',
		module => __PACKAGE__,
		commands => {
			'tap-harness' => sub {
				my $info   = shift;
				require TAP::Harness::Env;
				my $tester = TAP::Harness::Env->create({ verbosity => $info->verbose, lib => rel2abs(catdir(qw/blib lib/)), color => -t STDOUT });
				my @files  = $info->graph->unalias($info->arguments);

				my $results = $tester->runtests(@files);
				croak "Errors in testing.  Cannot continue.\n" if $results->has_errors;
			},
		},
	);
	return;
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	$graph->add_wildcard(dir => 't', pattern => '*.t', name => 'test-files');
	$graph->add_phony('test',
		action       => [ 'TAP/tap-harness', '$(test-files)' ],
		dependencies => [ 'build', '$(test-files)' ]
	);
	return;
}

1;

# ABSTRACT: A TAP consuming testing plugin

