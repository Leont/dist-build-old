package Dist::Build::CommandSet::Core;

use strict;
use warnings;

use base 'Dist::Build::Role::CommandSet';

use Carp qw/croak carp/;
use ExtUtils::Helpers qw/man1_pagename man3_pagename/;
use File::Spec::Functions qw/catfile catdir abs2rel rel2abs/;

sub get_actions {
	my ($self, $graph) = @_;
	my %commands = (
		'copy' => sub {
			my ($args, $source, $target) = @_;

			require File::Copy;
			File::Copy::copy($source, $target) or croak "Could not copy: $!";
			printf "cp %s %s\n", $source, $target;

			my ($atime, $mtime) = (stat $source)[8,9];
			utime $atime, $mtime, $target;
			chmod 0444 & ~umask, $target;

			return;
		},
		'rm-r' => sub {
			my ($args, @files) = @_;
			require File::Path;
			File::Path::rmtree(\@files, $args->{verbose}, 0);
			return;
		},
		'mkdir' => sub {
			my ($args, $target) = @_;
			File::Path::mkpath($target, $args->{verbose});
			return;
		},
		'touch' => sub {
			my ($args, $target) = @_;

			open my $fh, '>', $target or croak "Could not create $target: $!";
			close $fh or croak "Could not create $target: $!";
		},
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
	$commands{pl_to_blib} = sub {
		my ($opts, $source, $target) = @_;
		$commands{copy}->($opts, $source, $target);
		$commands{make_executable}->($opts, $target);
		return;
	};
	return \%commands;
}

sub has_action {
	my ($self, $name) = @_;
	return !!$self->get_actions->{$name};
}

sub get_trans {
	return {
		'to-blib' => sub {
			my $path = shift;
			return File::Spec->catfile('blib', $path);
		},
		'to-distshare' => sub {
			my ($source, $distname) = @_;
			return catfile(qw/blib lib auto share dist/, $distname, abs2rel($source, 'share'));
		},
		man1_filepath => sub {
			my $pm_file = shift;
			return catfile(qw/blib man3/, man1_pagename($pm_file));
		},
		man3_filepath => sub {
			my $pl_file = shift;
			return catfile(qw/blib man3/, man3_pagename($pl_file));
		},
	};
}

1;

