package Dist::Build::Plugin::TAP;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin Build::Graph::Role::Manipulator Build::Graph::Role::CommandProvider/;

use Carp;
use File::Next;
use File::Spec::Functions qw/catdir rel2abs/;
use TAP::Harness;

my $file_filter = sub { m/ \.t \z/xms };
my $descend_filter = sub { $_ ne 'CVS' and $_ ne '.svn' };

sub configure_commands {
	my ($self, $commandset) = @_;
	$commandset->add('TAP',
		module => __PACKAGE__,
		commands => {
			'tap-harness' => sub {
				my $info    = shift;
				my $tester  = TAP::Harness->new({ verbosity => $info->verbose, lib => rel2abs(catdir(qw/blib lib/)), color => -t STDOUT });
				my $results = $tester->runtests(@{ $info->arguments->{files} });
				croak "Errors in testing.  Cannot continue.\n" if $results->has_errors;
			},
		},
	);
	return;
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	my $iter = File::Next::files({ file_filter => $file_filter, descend_filter => $descend_filter, sort_files => 1 }, 't');
	my @files;
	while (defined(my $testfile = $iter->())) {
		push @files, $testfile;
	}

	$graph->add_phony('testbuild', dependencies => [ 'build', @files ]);
	$graph->add_phony('test', actions => { command => 'TAP/tap-harness', arguments => { files => \@files } }, dependencies => [ 'testbuild' ]);
	return;
}

1;

# ABSTRACT: A TAP consuming testing plugin

