package Dist::Build::Plugin::Install;

use Moo;
with qw/Dist::Build::Role::Graph::CommandProvider Dist::Build::Role::Graph::Manipulator Dist::Build::Role::OptionProvider/;

use ExtUtils::Install qw/install/;

sub configure_commands {
	return {
		install => sub {
			my $info = shift;
			install($info->install_paths->install_map, $info->verbose, 1, $info->option('uninst'));
			return;
		},
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;
	$graph->add_phony('install', actions => 'install', dependencies => ['build']);
	return;
}

sub options {
	return qw/uninst:1 dry_run:1/;
}

1;

# ABSTRACT: A Build.PL compatible installing plugin
