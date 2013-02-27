package Dist::Build;
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;

use Carp qw/croak/;

use CPAN::Meta;
use Dist::Build::Loader;

sub load_meta {
	my @files = @_;
	my ($metafile) = grep { -e $_ } @files or croak "No META information provided\n";
	return CPAN::Meta->load_file($metafile);
}

sub Build {
	my ($args, $env) = @_;
	my $meta = load_meta('MYMETA.json', 'MYMETA.yml');

	return Dist::Build::Loader->new->create_builder($meta, $args, $env)->run;
}

sub Build_PL {
	my @args = @_;
	my $meta = load_meta('META.json', 'META.yml');

	#XXX check_dependencies($meta, 'configure', 'requires');
	return Dist::Build::Loader->new->create_configurator($meta)->run(\@args);
}

1;

# ABSTRACT: A modern module builder, author tools not included!
