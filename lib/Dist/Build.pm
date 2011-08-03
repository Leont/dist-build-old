package Dist::Build;
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;

use Carp;

use Dist::Build::Loader;
use Dist::Build::Util qw/check_dependencies load_meta/;

sub Build {
	my @args = @_;
	my $meta = load_meta('MYMETA.json', 'MYMETA.yml');

	my $loader = Dist::Build::Loader->new(arguments => \@args, environment => \%ENV);
	my $builder = $loader->create_builder($meta);

	my $action = @args ? shift @args : 'build';
	return $builder->run($action);
}

sub Build_PL {
	my @args = @_;
	my $meta = load_meta('META.json', 'META.yml');

	#XXX check_dependencies($meta, 'configure', 'requires');
	my $loader = Dist::Build::Loader->new(arguments => \@args, environment => \%ENV);
	my $configurator = $loader->create_configurator($meta);
	$configurator->write_buildscript(\@args);
	$configurator->write_mymeta;
	return;
}

1;

# ABSTRACT: A modern module builder, author tools not included!
