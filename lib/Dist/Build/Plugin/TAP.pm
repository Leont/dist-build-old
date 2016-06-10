package Dist::Build::Plugin::TAP;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin/;

use Carp;
use File::Spec::Functions qw/catdir rel2abs/;

sub get_commands {
	return {
		'tap-harness' => sub {
			my ($args, @files) = @_;
			my %test_args = (
				(color => 1) x !!-t STDOUT,
				%{$args},
				lib => [ map { rel2abs(catdir('blib', $_)) } qw/arch lib/ ],
			);
			$test_args{verbosity} = $test_args{verbose} if exists $test_args{verbose};
			require TAP::Harness::Env;
			my $tester  = TAP::Harness::Env->create(\%test_args);
			my $results = $tester->runtests(@files);
			croak "Errors in testing.  Cannot continue.\n" if $results->has_errors;
		}
	};
}

sub manipulate_graph {
	my $self = shift;

	$self->add_wildcard('test-files', dir => 't', pattern => '*.t');
	$self->add_phony('test',
		action       => [ 'tap-harness', '%(verbose,jobs)', '@(test-files)' ],
		dependencies => [ 'build', '@(test-files)' ]
	);
	return;
}

1;

# ABSTRACT: A TAP consuming testing plugin

