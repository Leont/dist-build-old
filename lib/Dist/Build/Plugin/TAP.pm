package Dist::Build::Plugin::TAP;

use Moose;
with qw/Dist::Build::Role::Graph::Command Dist::Build::Role::Graph::Manipulator/;

use Carp;
use File::Next;
use File::Spec::Functions qw/catdir rel2abs/;
use TAP::Harness;

my $file_filter = sub { m/ \.t \z/xms };
my $descend_filter = sub { $_ ne 'CVS' and $_ ne '.svn' };

sub configure_commands {
	my ($self, $commands) = @_;
	$commands->add('tap-harness', sub {
		my $info = shift;
		my $tester = TAP::Harness->new({verbosity => $info->verbose, lib => rel2abs(catdir(qw/blib lib/)), color => -t STDOUT});
		my $results = $tester->runtests(@{ $info->arguments->{files} });
		croak "Errors in testing.  Cannot continue.\n" if $results->has_errors;
	});
	return;
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	my $iter = File::Next::files({ file_filter => $file_filter, descend_filter => $descend_filter, sort_files => 1 }, 't');
	my @files;
	while (defined(my $testfile = $iter->())) {
		push @files, $testfile;
		$graph->add_file($testfile);
	}

	$graph->add_phony('testdeps', actions => { command => 'checkdeps', arguments => { phases => [qw/runtime build test/] } });
	$graph->add_phony('testbuild', dependencies => [ 'build', @files ]);
	$graph->add_phony('test', actions => { command => 'tap-harness', arguments => { files => \@files } }, dependencies => [ 'testbuild', 'testdeps' ]);
	return;
}

1;

# ABSTRACT: A TAP consuming testing plugin

