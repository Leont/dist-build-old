package Dist::Build::Plugin::CopyPM;

use Moose;
with qw/Dist::Build::Role::GraphManipulator/;

use File::Spec::Functions;
use File::Next;

my $file_filter = sub { m/ \. p(?:m|od) \z/xms };
my $descend_filter = sub { $_ ne 'CVS' and $_ ne '.svn' };

sub command_plugins {
	return 'Sanity';
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	my $iter = File::Next::files({ file_filter => $file_filter, descend_filter => $descend_filter }, 'lib');
	my @destinations;
	while (defined(my $source = $iter->())) {
		my $destination = catfile('blib', $source);
		$graph->add_file($source);
		$graph->add_file($destination, actions => { command => 'copy', arguments => { source => $source } });
		push @destinations, $destination;
	}
	if (@destinations) {
		my $copy_pm = $graph->add_phony('copy_pm', dependencies => \@destinations);
		$graph->get_node('build')->add_dependencies('copy_pm');
	}
	return;
}

1;

# ABSTRACT: Plugin for copying Perl modules from lib to blib
