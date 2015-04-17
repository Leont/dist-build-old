package Dist::Build::Plugin::CopyPM;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin/;

sub get_commands {
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

	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
