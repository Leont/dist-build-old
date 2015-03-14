package Dist::Build::Plugin::Core;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin/;

use Carp;

sub get_commands {
	return {
		'copy' => sub {
			my ($args, $source, $target) = @_;

			if (-f $target) {
				require File::Path;
				File::Path::rmtree($target, $args->{verbose}, 0);
			}
			else {
				require File::Basename;
				my $dirname = File::Basename::dirname($target);
				if (!-d $dirname) {
					require File::Path;
					File::Path::mkpath($dirname, $args->{verbose});
				}
			}

			require File::Copy;
			File::Copy::copy($source, $target) or croak "Could not copy: $!";
			printf "cp %s %s\n", $source, $target;

			my ($atime, $mtime) = (stat $source)[8,9];
			utime $atime, $mtime, $target;
			chmod 0444, $target;

			return;
		},
		'rm-r' => sub {
			my ($args, @files) = @_;
			require File::Path;
			File::Path::rmtree(\@files, $args->{verbose}, 0);
			return;
		},
		'mkdir' => sub {
			my ($args, $target) = @_;
			File::Path::mkpath($target, $args->{verbose});
			return;
		},
		'touch' => sub {
			my ($args, $target) = @_;

			require File::Basename;
			my $dirname = File::Basename::dirname($target);
			if (!-d $dirname) {
				require File::Path;
				File::Path::mkpath($dirname, $args->{verbose});
			}

			open my $fh, '>', $target or croak "Could not create $target: $!";
			close $fh or croak "Could not create $target: $!";
		},
	};
}

sub get_substs {
	return {
		'to-blib' => sub {
			my $path = shift;
			return File::Spec->catfile('blib', $path);
		},
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;
	my @exists = map { File::Spec->catdir('blib', $_, '.exists') } qw/lib arch script/;
	$graph->add_file($_, action => [ 'Core/touch', '%(verbose)', '$(target)' ]) for @exists;
	$graph->add_variable('exist-files', @exists);
	$graph->add_phony('config', dependencies => [ '@(exist-files)' ]);
	$graph->add_variable('build-elements', 'config');
	$graph->add_phony('build', dependencies => [ '@(build-elements)' ]);
	$graph->add_variable('clean-files', 'blib');
	$graph->add_phony('clean', action => [ 'Core/rm-r', '%(verbose)', '@(clean-files)']);
	$graph->add_variable('realclean-files', qw/MYMETA.json MYMETA.yml Build _build/);
	$graph->add_phony('realclean', action => [ 'Core/rm-r', '%(verbose)', '@(realclean-files)'], dependencies => [ 'clean']);
	return;
}

1;

# ABSTRACT: Plugin implemented the bare neceseties of any module build process
