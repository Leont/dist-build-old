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

			if (-f $target) {
				require File::Path;
				File::Path::rmtree($target, $info->verbose, 0);
			}
			else {
				require File::Basename;
				my $dirname = File::Basename::dirname($target);
				if (!-d $dirname) {
					require File::Path;
					File::Path::mkpath($dirname, $info->verbose);
				}
			}

			require File::Copy;
			File::Copy::copy($source, $target) or croak "Could not copy: $!";
			printf "cp %s %s\n", $source, $target;

			my ($stat, $atime, $mtime) = (stat $source)[2,8,9];
			utime $atime, $mtime, $target;
			chmod $stat & 0444, $target;

			return;
		},
		'rm-r' => sub {
			my $info = shift;
			my @files = $info->arguments;
			require File::Path;
			File::Path::rmtree(\@files, $info->verbose, 0);
			return;
		},
		'mkdir' => sub {
			my $info = shift;
			require File::Path;
			File::Path::mkpath($info->name, $info->verbose);
			return;
		},
		'touch' => sub {
			my $info = shift;
			my $target = $info->name;

			require File::Basename;
			my $dirname = File::Basename::dirname($target);
			if (!-d $dirname) {
				require File::Path;
				File::Path::mkpath($dirname, $info->verbose);
			}

			open my $fh, '>', $target;
		},
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;
	my @exists = map { File::Spec->catdir('blib', $_, '.exists') } qw/lib arch script/;
	$graph->add_file($_, action => [ 'Core/touch' ]) for @exists;
	$graph->add_variable('exist-files', @exists);
	$graph->add_phony('config', dependencies => [ '$(exist-files)' ]);
	$graph->add_phony('build', dependencies => [ 'config' ]);
	$graph->add_variable('clean-files', 'blib');
	$graph->add_phony('clean', action => [ 'Core/rm-r', '$(clean-files)']);
	$graph->add_variable('realclean-files', qw/MYMETA.json MYMETA.yml Build _build/);
	$graph->add_phony('realclean', action => [ 'Core/rm-r', '$(realclean-files)'], dependencies => [ 'clean']);
	return;
}

1;

# ABSTRACT: Plugin implemented the bare neceseties of any module build process
