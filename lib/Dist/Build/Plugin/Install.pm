package Dist::Build::Plugin::Install;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Manipulator Build::Graph::Role::CommandProvider Dist::Build::Role::OptionProvider/;

sub _get_commands {
	return {
		'install' => sub {
			my $info = shift;
			require ExtUtils::Install;
			ExtUtils::Install::install($info->install_paths->install_map, $info->verbose, 1, $info->option('uninst'));
			return;
		},
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;
	$graph->add_phony('install', action => [ 'Install/install' ], dependencies => ['build']);
	return;
}

sub options {
	return qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s uninst:1 dry_run:1/;
}

1;

# ABSTRACT: A Build.PL compatible installing plugin
