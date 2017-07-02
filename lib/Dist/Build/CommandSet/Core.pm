package Dist::Build::CommandSet::Core;

use strict;
use warnings;

use Carp qw/croak carp/;
use ExtUtils::Helpers qw/man1_pagename man3_pagename/;
use File::Spec::Functions qw/catfile catdir abs2rel rel2abs/;

sub add_to {
	my ($class, $graph, %args) = @_;

	my %commands = (
		make_executable => sub {
			my ($args, $out, $target) = @_;
			require ExtUtils::Helpers;
			ExtUtils::Helpers::make_executable($out, $target);
		},
		manify => sub {
			my ($opts, $input_file, $output_file) = @_;
			my $section = $opts->{section} || 3;
			require Pod::Man;
			Pod::Man->new(section => $section)->parse_from_file($input_file, $output_file);
			print "Manifying $output_file\n" if $opts->{verbose} && $opts->{verbose} > 0;
			return;
		},
		'tap-harness' => sub {
			my ($args, @files) = @_;
			my %test_args = (
				(color => 1) x !!-t STDOUT,
				%{$args},
				lib => [ map { rel2abs(catdir('blib', $_)) } qw/arch lib/ ],
			);
			$test_args{verbosity} = delete $test_args{verbose} if exists $test_args{verbose};
			require TAP::Harness::Env;
			my $tester  = TAP::Harness::Env->create(\%test_args);
			my $results = $tester->runtests(@files);
			croak "Errors in testing.  Cannot continue.\n" if $results->has_errors;
		},
		'install' => sub {
			my $args = shift;
			require ExtUtils::Install;
			ExtUtils::Install::install($args->{install_paths}->install_map, $args->{verbose}, 0, $args->{uninst});
			return;
		},
	);

	for my $key (keys %commands) {
		$graph->actions->add($key, $commands{$key});
	}

	my %transformations = (
		'to-blib' => sub {
			my $path = shift;
			return File::Spec->catfile('blib', $path);
		},
		'abs2rel' => sub {
			my ($source, $base) = @_;
			return abs2rel($source, $base);
		},
		'prepend-dirs' => sub {
			my @parts = @_;
			return catfile(@parts);
		},
		man1_filepath => sub {
			my $pm_file = shift;
			return catfile(qw/blib bindoc/, man1_pagename($pm_file));
		},
		man3_filepath => sub {
			my $pl_file = shift;
			return catfile(qw/blib libdoc/, man3_pagename($pl_file));
		},
	);

	for my $key (keys %transformations) {
		$graph->transformations->add($key, $transformations{$key});
	}

	return;
}

1;

