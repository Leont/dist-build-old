package Dist::Build::Plugin::Core;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin/;

use Carp;

sub get_commands {
	return {
		'copy' => sub {
			my ($args, $source, $target) = @_;

			if (-e $target) {
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
		'install' => sub {
			my $args = shift;
			require ExtUtils::Install;
			ExtUtils::Install::install($args->{install_paths}->install_map, $args->{verbose}, 0, $args->{uninst});
			return;
		},
	};
}

sub get_trans {
	return {
		'to-blib' => sub {
			my $path = shift;
			return File::Spec->catfile('blib', $path);
		},
	};
}

sub manipulate_graph {
	my $self = shift;
	my @exists = map { File::Spec->catdir('blib', $_, '.exists') } qw/lib arch script/;
	$self->add_file($_, action => [ 'touch', '%(verbose)', '$(target)' ]) for @exists;
	$self->add_variable('exist-files', @exists);
	$self->add_phony('config', dependencies => [ '@(exist-files)' ]);
	$self->add_variable('build-elements', 'config');
	$self->add_phony('build', dependencies => [ '@(build-elements)' ]);
	$self->add_variable('clean-files', 'blib');
	$self->add_phony('clean', action => [ 'rm-r', '%(verbose)', '@(clean-files)']);
	$self->add_variable('realclean-files', qw/@(clean-files) MYMETA.json MYMETA.yml Build _build/);
	$self->add_phony('realclean', action => [ 'rm-r', '%(verbose)', '@(realclean-files)']);
	$self->add_phony('install', action => [ 'install', '%(install_paths,verbose,uninst)' ], dependencies => ['build']);
	return;
}

sub options {
	return qw/uninst:1 dry_run:1/;
}

1;

# ABSTRACT: Plugin implemented the bare necessities of any distribution build process
