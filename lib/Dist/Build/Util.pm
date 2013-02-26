package Dist::Build::Util;

use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT_OK = qw/check_dependencies warn_dependencies load_meta/;

use Carp qw/croak carp/;
use CPAN::Meta;
use Module::Metadata;

sub get_dependencies {
	my ($meta, $phase, $type) = @_;

	my @errors;
	my $reqs = $meta->effective_prereqs->requirements_for($phase, $type);
	for my $module ($reqs->required_modules) {
		my $version;
		if ($module eq 'perl') {
			$version = $];
		}
		else {
			my $metadata = Module::Metadata->new_from_module($module);
			push @errors, "Module '$module' is not installed" and next if not defined $metadata;
			$version = eval { $metadata->version };
		}
		push @errors, "Missing version info for module '$module'" if not $version;
		push @errors, sprintf 'Version %s is not in range \'%s\'', $version, $reqs->as_string_hash->{$module} if not $reqs->accepts_module($module, $version);
	}
	return @errors;
}

sub check_dependencies {
	my ($meta, $phase, $type) = @_;
	my @errors = get_dependencies($meta, $phase, $type);
	croak join "\n", @errors if @errors;
	return;
}

sub warn_dependencies {
	my ($meta, $phase, $type) = @_;
	my @errors = get_dependencies($meta, $phase, $type);
	carp join "\n", @errors if @errors;
	return;
}

sub load_meta {
	my @files = @_;
	my ($metafile) = grep { -e $_ } @files or croak "No META information provided\n";
	return CPAN::Meta->load_file($metafile);
}

1;

# ABSTRACT: Various utility functions for Dist::Build
