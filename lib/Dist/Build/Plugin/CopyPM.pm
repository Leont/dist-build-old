package Dist::Build::Plugin::CopyPM;

use strict;
use warnings;

use parent qw/Build::Graph::Role::CommandProvider Dist::Build::Role::Manipulator/;

use File::Spec::Functions qw/catfile/;

sub _get_commands {
	return {
		make_executable => sub {
			my $info = shift;
			my $target = $info->target;
			require ExtUtils::Helpers;
			ExtUtils::Helpers::make_executable($target);
		},
		pl_to_blib => [ 'Core/copy', 'CopyPM/make_executable' ],
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	$graph->add_phony('copy_pm', dependencies => ['$(pm-blib)']);
	$graph->add_phony('copy_pl', dependencies => ['$(pl-blib)']);
	$graph->get_node('build')->add_dependencies('copy_pm', 'copy_pl');

	my $pms = $graph->add_wildcard(dir => 'lib', pattern => '*.{pm,pod}', name => 'pm-files');
	$graph->add_subst($pms,
		subst  => sub { my $source = shift; catfile('blib', $source) },
		action => sub { my ($target, $source) = @_; [ 'Core/copy', $source ] },
		name   => 'pm-blib',
	);
	my $pls = $graph->add_wildcard(dir => 'script', pattern => '*', name => 'pl-files');
	$graph->add_subst($pls,
		subst  => sub { my $source = shift; catfile('blib', $source) },
		action => sub { my ($target, $source) = @_; [ 'CopyPM/pl_to_blib', $source ] },
		name   => 'pl-blib',
	);
	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
