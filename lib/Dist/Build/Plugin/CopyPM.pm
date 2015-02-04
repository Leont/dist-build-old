package Dist::Build::Plugin::CopyPM;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin Build::Graph::Role::Manipulator/;

use File::Spec::Functions qw/catfile/;

sub dependencies {
	return 'Dist::Build::Plugin::Sanity';
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	$graph->add_phony('copy_pm');
	$graph->get_node('build')->add_dependencies('copy_pm');

	my $pms = $graph->add_wildcard(dir => 'lib', pattern => '*.{pm,pod}', name => 'pm-files');
	$graph->add_subst($pms,
		subst      => sub { my $source = shift; catfile('blib', $source) },
		action     => sub { my ($target, $source) = @_; [ 'Core/copy', { source => $source } ] },
		dependents => 'copy_pm'
	);
	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
