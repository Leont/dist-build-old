package Dist::Build::Plugin::Sanity;

use Moo;
with qw/Dist::Build::Role::Graph::Command Dist::Build::Role::Graph::Manipulator/;

use Carp;
use CPAN::Meta::Check qw/verify_dependencies/;
use File::Copy 'copy';

sub configure_commands {
	my ($self, $commands) = @_;
	$commands->add('checkdeps', sub {
		my $info = shift;
		my $phases = $info->arguments->{phases};
		my @croak = verify_dependencies($info->meta_info, $phases, 'requires');
		croak join "\n", @croak if @croak;
		my @carp = verify_dependencies($info->meta_info, $phases, 'recommends');
		carp join "\n", @carp if @carp;
	});
	$commands->add('copy', sub {
		my $info = shift;
		my $source = $info->arguments->{source};
		copy($source, $info->name) or croak "Could not copy: $!";
		return;
	});
	return;
}

sub manipulate_graph {
	my ($self, $graph) = @_;
	$graph->add_phony('builddeps', actions => { command => 'checkdeps', arguments => { phases => [qw/runtime build/] } });
	$graph->add_phony('build', dependencies => ['builddeps']);
	return;
}

1;

# ABSTRACT: Plugin implemented the bare neceseties of any module build process
