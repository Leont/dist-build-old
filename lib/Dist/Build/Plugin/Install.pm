package Dist::Build::Plugin::Install;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin/;

sub get_commands {
	return {
		'install' => sub {
			my $args = shift;
			require ExtUtils::Install;
			ExtUtils::Install::install($args->{install_paths}->install_map, $args->{verbose}, 0, $args->{uninst});
			return;
		},
	};
}

sub manipulate_graph {
	my ($self) = @_;
	$self->add_phony('install', action => [ 'install', '%(install_paths,verbose,uninst)' ], dependencies => ['build']);
	return;
}

sub options {
	return qw/uninst:1 dry_run:1/;
}

1;

# ABSTRACT: A Build.PL compatible installing plugin
