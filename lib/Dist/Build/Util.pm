package Dist::Build::Util;

use strict;
use warnings FATAL => 'all';

use Exporter 5.57 'import';
our @EXPORT_OK = qw/load_meta/;

use Carp qw/croak carp/;
use CPAN::Meta;

sub load_meta {
	my @files = @_;
	my ($metafile) = grep { -e $_ } @files or croak "No META information provided\n";
	return CPAN::Meta->load_file($metafile);
}

1;

# ABSTRACT: Various utility functions for Dist::Build
