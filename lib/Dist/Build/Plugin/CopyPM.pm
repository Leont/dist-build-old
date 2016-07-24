package Dist::Build::Plugin::CopyPM;

use strict;
use warnings;

use base qw/Dist::Build::Role::Plugin/;

use ExtUtils::Helpers qw/man1_pagename man3_pagename/;
use File::Spec::Functions qw/catfile/;

sub get_actions {
	my ($self, %args) = @_;
	return {
		make_executable => sub {
			my ($args, $target) = @_;
			require ExtUtils::Helpers;
			ExtUtils::Helpers::make_executable($target);
		},
		pl_to_blib => sub {
			my ($opts, $source, $target) = @_;
			$self->run_command('Core/copy', $opts, $source, $target);
			$self->run_command('make_executable', $opts, $target);
			return;
		},
		manify => sub {
			my ($opts, $input_file, $output_file) = @_;
			my $section = $opts->{section} || 3;
			require Pod::Man;
			Pod::Man->new(section => $section)->parse_from_file($input_file, $output_file);
			print "Manifying $output_file\n" if $opts->{verbose} && $opts->{verbose} > 0;
			return;
		},
	};
}

sub get_trans {
	return {
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

sub manipulate_graph {
	my $self = shift;

	$self->add_wildcard('pm-files', dir => 'lib', pattern => '*.{pm,pod}');
	$self->add_subst('pm-blib', 'pm-files',
		trans  => [ 'Core/to-blib', '$(source)' ],
		action => [ 'Core/copy', '%(verbose)', '$(source)', '$(target)' ],
	);
	$self->add_phony('copy_pm', dependencies => ['@(pm-blib)'], add_to => 'build-elements');

	$self->add_wildcard('pl-files', dir => 'script', pattern => '*');
	$self->add_subst('pl-blib', 'pl-files',
		trans  => [ 'Core/to-blib', '$(source)' ],
		action => [ 'pl_to_blib', '%(verbose)', '$(source)', '$(target)' ],
	);
	$self->add_phony('copy_pl', dependencies => ['@(pl-blib)'], add_to => 'build-elements');

	$self->add_subst('man3-pages', 'pm-files',
		trans  => [ 'man3_filepath', '$(source)' ],
		action => [ 'manify', '%(verbose)', '$(source)', '$(target)', ],
		dependencies => [ catfile(qw/blib man3 .exists/) ],
	);
	$self->add_subst('man1-pages', 'pl-files',
		trans  => [ 'man1_filepath', '$(source)' ],
		action => [ 'manify', { verbose => '$(verbose?)', section => 1 }, '$(source)', '$(target)' ],
		dependencies => [ catfile(qw/blib man1 .exists/) ],
	);
	$self->add_phony('manify-pods', dependencies => [ '@(man1-pages)', '@(man3-pages)' ], add_to => 'build-elements');
	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
