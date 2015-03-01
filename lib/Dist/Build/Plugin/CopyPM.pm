package Dist::Build::Plugin::CopyPM;

use strict;
use warnings;

use parent qw/Build::Graph::Role::CommandProvider Dist::Build::Role::Manipulator/;

use File::Spec::Functions qw/catfile/;

sub _get_commands {
	return {
		make_executable => sub {
			my ($args, $target, $source) = @_;
			require ExtUtils::Helpers;
			ExtUtils::Helpers::make_executable($target);
		},
		pl_to_blib => [ 'Core/copy', 'CopyPM/make_executable' ],
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
		action => [ 'Core/copy', '%(verbose)', '$(target)', '$(source)' ],
	);
	my $pls = $graph->add_wildcard('pl-files', dir => 'script', pattern => '*');
	$graph->add_subst('pl-blib', $pls,
		subst  => [ 'Core/to-blib', '$(source)' ],
		action => [ 'CopyPM/pl_to_blib', '%(verbose)', '$(target)', '$(source)' ],
	);
	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
