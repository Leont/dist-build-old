package Dist::Build::Plugin::TAP;

use Any::Moose;
with qw/Dist::Build::Role::Plugin Dist::Build::Role::GraphManipulator/;

use File::Next;
use File::Spec::Functions qw/catdir rel2abs/;
use TAP::Harness;

my $file_filter = sub { m/ \.t \z/xms };
my $descend_filter = sub { $_ ne 'CVS' and $_ ne '.svn' };

sub manipulate_graph {
	my $self  = shift;
	my $graph = $self->builder->graph;

	$graph->commands->add('tap-harness', sub {
		my $info = shift;
		my $tester = TAP::Harness->new({verbosity => $info->verbose, lib => rel2abs(catdir(qw/blib lib/)), color => -t STDOUT});
		$tester->runtests($info->dependencies->with_type('testfile'))->has_errors and exit 1;
	});

	my $iter = File::Next::files({ file_filter => $file_filter, descend_filter => $descend_filter, sort_files => 1 }, 't');
	my @files;
	while (defined(my $testfile = $iter->())) {
		push @files, $testfile;
		$graph->add_file($testfile);
	}

	$graph->add_phony('testbuild', dependencies => ['build'] );
	$graph->add_phony('test', actions => 'tap-harness', dependencies => { testbuild => undef, map { $_ => 'testfile' } @files });

	$self->builder->connect_node('test');
	return;
}

1;

__END__

# ABSTRACT: A TAP consuming testing plugin

