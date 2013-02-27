package Dist::Build::Plugin::Install;

use Moose;
with qw/Dist::Build::Role::Graph::Command Dist::Build::Role::Graph::Manipulator Dist::Build::Role::OptionProvider/;

use ExtUtils::Install qw/install/;
use ExtUtils::InstallPaths;

sub configure_commands {
	my ($self, $commands) = @_;
	$commands->add('install', sub {
		my $info = shift;
		my $paths = ExtUtils::InstallPaths->new($info->options, config => $info->config, dist_name => $info->meta_info->name);
		install($paths->install_map, $info->verbose, 1, $info->option('uninst'));
		return;
	});
	return;
}

sub manipulate_graph {
	my ($self, $graph) = @_;
	$graph->add_phony('install', actions => 'install', dependencies => [ 'build' ]);
	return;
}

sub options {
	return qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s uninst:1 dry_run:1/;
}

1;

# ABSTRACT: A Build.PL compatible installing plugin
