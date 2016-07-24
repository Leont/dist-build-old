package Dist::Build::Plugin::CopyPM;

use strict;
use warnings;

use base qw/Dist::Build::Role::Plugin/;

use File::Spec::Functions qw/catfile/;

sub manipulate_graph {
	my ($self, $graph) = @_;

	$graph->add_wildcard('pm-files', dir => 'lib', pattern => '*.{pm,pod}');
	$graph->add_subst('pm-blib', 'pm-files',
		trans  => [ 'Core/to-blib', '$(source)' ],
		action => [ 'Core/copy', '%(verbose)', '$(source)', '$(target)' ],
	);
	$graph->add_phony('copy_pm', dependencies => ['@(pm-blib)'], add_to => 'build-elements');

	$graph->add_wildcard('pl-files', dir => 'script', pattern => '*');
	$graph->add_subst('pl-blib', 'pl-files',
		trans  => [ 'Core/to-blib', '$(source)' ],
		action => [ 'Core/pl_to_blib', '%(verbose)', '$(source)', '$(target)' ],
	);
	$graph->add_phony('copy_pl', dependencies => ['@(pl-blib)'], add_to => 'build-elements');

	$graph->add_subst('man3-pages', 'pm-files',
		trans  => [ 'Core/man3_filepath', '$(source)' ],
		action => [ 'Core/manify', '%(verbose)', '$(source)', '$(target)', ],
		dependencies => [ catfile(qw/blib man3 .exists/) ],
	);
	$graph->add_subst('man1-pages', 'pl-files',
		trans  => [ 'Core/man1_filepath', '$(source)' ],
		action => [ 'Core/manify', { verbose => '$(verbose?)', section => 1 }, '$(source)', '$(target)' ],
		dependencies => [ catfile(qw/blib man1 .exists/) ],
	);
	$graph->add_phony('manify-pods', dependencies => [ '@(man1-pages)', '@(man3-pages)' ], add_to => 'build-elements');
	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
