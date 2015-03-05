package Dist::Build::Plugin::CopyPM;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin/;

sub _get_commands {
	my ($self, %args) = @_;
	my $graph = $self->graph;
	return {
		make_executable => sub {
			my ($args, $target) = @_;
			require ExtUtils::Helpers;
			ExtUtils::Helpers::make_executable($target);
		},
		pl_to_blib => sub {
			my ($opts, $source, $target) = @_;
			$graph->run_command('Core/copy', $opts, $source, $target);
			$graph->run_command('CopyPM/make_executable', $opts, $target);
			return;
		},
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	$graph->add_phony('copy_pm', dependencies => ['@(pm-blib)']);
	$graph->add_phony('copy_pl', dependencies => ['@(pl-blib)']);
	$graph->get_node('build')->add_dependencies('copy_pm', 'copy_pl');

	my $pms = $graph->add_wildcard('pm-files', dir => 'lib', pattern => '*.{pm,pod}');
	$graph->add_subst('pm-blib', $pms,
		subst  => [ 'Core/to-blib', '$(source)' ],
		action => [ 'Core/copy', '%(verbose)', '$(source)', '$(target)' ],
	);
	my $pls = $graph->add_wildcard('pl-files', dir => 'script', pattern => '*');
	$graph->add_subst('pl-blib', $pls,
		subst  => [ 'Core/to-blib', '$(source)' ],
		action => [ 'CopyPM/pl_to_blib', '%(verbose)', '$(source)', '$(target)' ],
	);
	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
