package Dist::Build::Plugin::CopyPM;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin Dist::Build::Role::Manipulator/;

use File::Spec::Functions qw/catfile/;

sub dependencies {
	return 'Dist::Build::Plugin::Sanity';
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	$graph->add_phony('copy_pm', dependencies => ['$(pm-blib)']);
	$graph->get_node('build')->add_dependencies('copy_pm');

	my $pms = $graph->add_wildcard(dir => 'lib', pattern => '*.{pm,pod}', name => 'pm-files');
	$graph->add_subst($pms,
		subst  => sub { my $source = shift; catfile('blib', $source) },
		action => sub { my ($target, $source) = @_; [ 'Core/copy', $source ] },
		name   => 'pm-blib',
	);
	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
