package Dist::Build::Plugin::CopyPM;

use Any::Moose;
with qw/Dist::Build::Role::Plugin Dist::Build::Role::GraphManipulator/;

use File::Spec::Functions;
use File::Next;

my $file_filter = sub { m/ \. p(?:m|od) \z/xms };
my $descend_filter = sub { $_ ne 'CVS' and $_ ne '.svn' };

sub manipulate_graph {
	my $self  = shift;
	my $graph = $self->builder->graph;

	my $iter = File::Next::files({ file_filter => $file_filter, descend_filter => $descend_filter }, 'lib');
	my @destinations;
	while (defined(my $source = $iter->())) {
		my $destination = catfile('blib', $source);
		$graph->add_file($source);
		$graph->add_file($destination, actions => 'copy', dependencies => { $source => 'source' });
		push @destinations, $destination;
	}
	if (@destinations) {
		my $copy_pm = $graph->add_phony('copy_pm', dependencies => \@destinations);
		$graph->get_node('build')->dependencies->add('copy_pm');
	}
	return;
}

1;

__END__

# ABSTRACT: plugin for copying Perl modules from lib to blib
