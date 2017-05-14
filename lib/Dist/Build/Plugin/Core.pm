package Dist::Build::Plugin::Core;

use strict;
use warnings;

use base qw/Dist::Build::Role::Plugin/;

sub manipulate_graph {
	my ($self, $graph) = @_;
	my @exists = map { File::Spec->catdir('blib', $_, '.exists') } qw/lib arch script man1 man3/;
	$graph->add_file($_, action => [ 'touch', '%(verbose)', '$(target)' ], add_to => 'exist-files') for @exists;
	$graph->add_phony('config', dependencies => [ '@(exist-files)' ], add_to => 'build-elements');
	$graph->add_phony('build', dependencies => [ '@(build-elements)' ]);
	$graph->add_variable('clean-files', 'blib');
	$graph->add_phony('clean', action => [ 'rm-r', '%(verbose)', '@(clean-files)']);
	$graph->add_variable('realclean-files', qw/@(clean-files) MYMETA.json MYMETA.yml Build _build/);
	$graph->add_phony('realclean', action => [ 'rm-r', '%(verbose)', '@(realclean-files)']);
	$graph->add_phony('install', action => [ 'install', '%(install_paths,verbose,uninst)' ], dependencies => ['build']);
	return;
}

sub options {
	return qw/uninst:1 dry_run:1/;
}

1;

# ABSTRACT: Plugin implemented the bare necessities of any distribution build process
