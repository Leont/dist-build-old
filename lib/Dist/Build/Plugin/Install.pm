package Dist::Build::Plugin::Install;

use Moose;
with qw/Dist::Build::Role::Command Dist::Build::Role::GraphManipulator/;

use File::Spec::Functions qw//;
use ExtUtils::Install qw/install/;
use ExtUtils::InstallPaths;

sub configure_commands {
	my $self = shift;
	$self->graph->commands->add('install', sub {
		my $info = shift;
		my $paths = ExtUtils::InstallPaths->new($info->options, config => $info->config, dist_name => $self->builder->name);
		install($paths->install_map, $info->verbose, 1, $info->option('uninst'));
		return;
	});
	return;
}

sub manipulate_graph {
	my $self = shift;
	$self->graph->add_phony('install', actions => 'install', dependencies => [ 'build' ]);
	$self->builder->connect_node('install');
	return;
}

after 'configure' => sub {
	my ($class, $loader) = @_;
	$loader->add_options(qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s uninst:1 dry_run:1/);
};

1;

# ABSTRACT: A Build.PL compatible installing plugin
