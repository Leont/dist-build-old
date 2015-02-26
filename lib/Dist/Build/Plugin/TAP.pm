package Dist::Build::Plugin::TAP;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Manipulator Build::Graph::Role::CommandProvider/;

use Carp;
use File::Spec::Functions qw/catdir rel2abs/;

sub _get_commands {
	return {
		'tap-harness' => sub {
			my ($args, @files) = @_;
			my %test_args = (
				%{$args},
				(color => 1) x !!-t STDOUT,
				lib => [ map { rel2abs(catdir(qw/blib/, $_)) } qw/arch lib/ ],
			);
			require TAP::Harness::Env;
			my $tester  = TAP::Harness::Env->create(\%test_args);
			my $results = $tester->runtests(@files);
			croak "Errors in testing.  Cannot continue.\n" if $results->has_errors;
		}
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	my $name = $self->name;
	$graph->add_wildcard('test-files', dir => 't', pattern => '*.t');
	$graph->add_phony('test',
		action       => [ 'TAP/tap-harness', '%(verbose)', '@(test-files)' ],
		dependencies => [ 'build', '@(test-files)' ]
	);
	return;
}

1;

# ABSTRACT: A TAP consuming testing plugin

