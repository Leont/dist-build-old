package Dist::Build::Plugin::TAP;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin Dist::Build::Role::Manipulator Build::Graph::Role::CommandProvider/;

use Carp;
use File::Spec::Functions qw/catdir rel2abs/;

sub configure_commands {
	my ($self, $commandset) = @_;
	$commandset->add('TAP',
		module => __PACKAGE__,
		commands => {
			'tap-harness' => sub {
				my $info  = shift;
				my @files = $info->arguments;
				my %test_args = (
					(verbosity => $info->option('verbose')) x!! defined $info->option('verbose'),
					(jobs => $info->option('jobs')) x!! defined $info->option('jobs'),
					(color => 1) x !!-t STDOUT,
					lib => [ map { rel2abs(catdir(qw/blib/, $_)) } qw/arch lib/ ],
				);
				require TAP::Harness::Env;
				my $tester  = TAP::Harness::Env->create(\%test_args);
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

