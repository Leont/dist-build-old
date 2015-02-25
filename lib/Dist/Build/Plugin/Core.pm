package Dist::Build::Plugin::Core;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Manipulator Build::Graph::Role::CommandProvider/;

use Carp;

sub _get_commands {
	return {
		'copy' => sub {
			my $info   = shift;
			my ($source) = $info->arguments;
			my $target = $info->name;

			require File::Path;
			require File::Basename;
			File::Path::mkpath(File::Basename::dirname($target));

			require File::Copy;
			File::Copy::copy($source, $target) or croak "Could not copy: $!";
			printf "cp %s %s\n", $source, $target if $info->verbose;
			return;
		},
		'rm-r' => sub {
			my $info = shift;
			my @files = $info->arguments;
			require File::Path;
			File::Path::rmtree(\@files, $info->verbose, 0);
			return;
		},
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;
	$graph->add_phony('build');
	$graph->add_named('clean-files', 'blib');
	$graph->add_phony('clean', action => [ 'Core/rm-r', '$(clean-files)']);
	$graph->add_named('realclean-files', qw/MYMETA.json MYMETA.yml Build _build/);
	$graph->add_phony('realclean', action => [ 'Core/rm-r', '$(realclean-files)'], dependencies => [ 'clean']);
	return;
}

1;

# ABSTRACT: Plugin implemented the bare neceseties of any module build process
