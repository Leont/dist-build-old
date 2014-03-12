package Dist::Build::Plugin::CopyPM;

use Moo;
with qw/Dist::Build::Role::Graph::Manipulator/;

use File::Spec::Functions qw/catfile/;
use File::Next;

my $file_filter = sub { m/ \. p(?:m|od) \z/xms };
my $descend_filter = sub { $_ ne 'CVS' and $_ ne '.svn' };

sub dependencies {
	return 'Dist::Build::Plugin::Sanity';
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	my $iter = File::Next::files({ file_filter => $file_filter, descend_filter => $descend_filter }, 'lib');
	my @destinations;
	while (defined(my $source = $iter->())) {
		my $destination = catfile('blib', $source);
		$graph->add_file($destination, actions => { command => 'Core/copy', arguments => { source => $source } });
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
