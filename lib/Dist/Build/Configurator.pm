package Dist::Build::Configurator;

use Moose;

use Build::Graph;
use ExtUtils::Helpers 0.007 qw/make_executable split_like_shell build_script/;
use File::Slurp qw/read_file write_file/;
use JSON 2 qw/encode_json/;
use List::MoreUtils qw/uniq/;

has meta_info => (
	is       => 'ro',
	isa      => 'CPAN::Meta',
	required => 1,
);

has name => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->meta_info->name;
	},
);

has version => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->meta_info->version;
	},
);

has plugins => (
	isa      => 'ArrayRef[Dist::Build::Role::Plugin]',
	traits   => ['Array'],
	default  => sub { [] },
	handles  => {
		plugins        => 'elements',
		search_plugins => 'grep',
	},
);

sub plugins_with {
	my ($self, $role) = @_;

	$role =~ s/ ^ - /Dist::Build::Role::/x;
	return $self->search_plugins(sub { $_->does($role) });
}

has info_class => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has graph => (
	is      => 'ro',
	isa     => 'Build::Graph',
	lazy    => 1,
	default => sub {
		my $self = shift;
		my $ret = Build::Graph->new(info_class => $self->info_class);
		$self->load_graph_plugins($ret);
		return $ret;
	},
);

sub load_graph_plugins {
	my ($self, $graph) = @_;
	for my $commandset ($self->plugins_with(-Command)) {
		$commandset->configure_commands($graph->commands);
	}
	for my $grapher ($self->plugins_with(-GraphManipulator)) {
		$grapher->manipulate_graph($graph);
	}
	return;
}

sub write_buildscript {
	my ($self, $arguments) = @_;
	my $meta = $self->meta_info;

	printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
	my $dir = $meta->name eq 'Dist-Build' ? 'lib' : 'inc';
	write_file('Build', "#!perl\nuse lib '$dir';\nuse Dist::Build;\nBuild(\\\@ARGV, \\\%ENV);\n");
	make_executable('Build');

	mkdir '_build' if not -d '_build';
	write_file(qw{_build/params}, encode_json($arguments));
	my @commands = uniq(map { $_->command_plugins } $self->plugins_with(-GraphManipulator));
	write_file(qw{_build/graph}, encode_json({commands => \@commands, graph => $self->graph->nodes_to_hashref }));
	return;
}

sub write_mymeta {
	my $self = shift;

	$self->meta_info->save('MYMETA.json');
	$self->meta_info->save('MYMETA.yml', { version => 1.4 });
	return;
}

1;

# ABSTRACT: The Dist-Build configuration stage
