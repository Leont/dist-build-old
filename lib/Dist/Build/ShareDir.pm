package Dist::Build::ShareDir;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use File::Find 'find';
use File::Spec::Functions qw/abs2rel catfile/;

sub add_methods {
	my ($self, $planner) = @_;

	$self->add_delegate($planner, 'dist_sharedir', sub {
		my ($dir, $dist_name) = @_;
		$dist_name ||= $planner->dist_name;

		my @outputs;
		find(sub {
			return unless -f;
			my $output = catfile(qw/blib lib auto share dist/, $dist_name, abs2rel($File::Find::name, $dir));
			$planner->copy_file(abs2rel($File::Find::name), $output);
			push @outputs, $output;
		}, $dir);

		ExtUtils::Builder::Node->new(
			target       => 'code',
			dependencies => \@outputs,
			phony        => 1,
		);
	});

	$self->add_delegate($planner, 'module_sharedir', sub {
		my ($dir, $module_name) = @_;
		(my $module_dir = $module_name) =~ s/::/-/g;

		my @outputs;
		find(sub {
			return unless -f;
			my $output = catfile(qw/blib lib auto share module/, $module_dir, abs2rel($File::Find::name, $dir));
			$planner->copy_file(abs2rel($File::Find::name), $output);
			push @outputs, $output;
		}, $dir);

		ExtUtils::Builder::Node->new(
			target       => 'code',
			dependencies => \@outputs,
			phony        => 1,
		);
	});
}

1;

# ABSTRACT: Sharedir support for Dist::Build

=head1 SYNOPSIS

 load_module("Dist::Build::ShareDir");
 dist_sharedir('share', 'Foo-Bar');
 module_sharedir('foo', 'Foo::Bar');

=head1 DESCRIPTION

This Dist::Build extension implements sharedirs. It does not take any arguments at loading time, and exposts two functions to the planner:

=head2 dist_sharedir($dir, $dist_name)

This marks C<$dir> as the source sharedir for the distribution C<$dist_name>. If C<$dist_name> isn't given, it defaults to the C<dist_name> of the planner.

=head2 module_sharedir($dir, $module_name)

This marks C<$dir> as the source sharedir for the module C<$module_name>.
