package Dist::Build::Loader;
use strict;
use warnings;

use Moose;

use Build::Graph;
use ExtUtils::BuildRC 0.003 qw/read_config/;
use ExtUtils::Config;
use ExtUtils::Helpers 0.007 qw/split_like_shell/;
use File::Slurp qw/read_file/;
use Getopt::Long qw/GetOptionsFromArray/;
use JSON 2 qw/decode_json/;
use Module::Runtime qw/require_module/;

has options => (
	isa => 'ArrayRef[Str]',
	traits => [ 'Array' ],
	handles => {
		add_options => 'push',
		options     => 'elements',
	},
	init_arg => undef,
	default => sub {
		[ qw/config=s% verbose:1/ ]
	},
);

has arguments => (
	isa => 'ArrayRef[Str]',
	traits => [ 'Array' ],
	required => 1,
	handles => {
		arguments => 'elements',
	},
);

has environment => (
	isa => 'HashRef[Str]',
	traits => [ 'Hash' ],
	required => 1,
	handles => {
		environment => 'elements',
		get_env     => 'get'
	},
);

has info_class => (
	is      => 'ro',
	isa     => 'Str',
	default => 'Dist::Build::Info',
);

#XXX: hardcoded for now.
my @modules = qw/-Sanity -CopyPM -TAP -Install/;
sub _modules_to_load {
	return @modules;
}

sub _load_plugins {
	my ($self, @plugins) = @_;
	my @modules = map { s/^-/Dist::Build::Plugin::/; $_ } @plugins;
	for my $module(@modules) {
		require_module($module);
		$module->configure($self);
	}
	return @modules;
}

sub create_builder {
	my ($self, $meta) = @_;
	my $pregraph = decode_json(read_file(q{_build/graph}));
	my $commandset = Build::Graph::CommandSet->new;
	for my $command_provider (@{ $pregraph->{commands} }) {
		my ($module) = $self->_load_plugins($command_provider);
		$module->new(plugin_name => $command_provider)->configure_commands($commandset);
	}
	my ($opt, $config) = $self->_parse_arguments;
	my $graph = Build::Graph->new(commands => $commandset, info_class => $self->info_class);
	$graph->load_from_hashref($pregraph->{graph});
	require Dist::Build::Builder;
	return Dist::Build::Builder->new(
		meta_info => $meta,
		options   => $opt,
		config    => $config,
		graph     => $graph,
	);
}

sub create_configurator {
	my ($self, $meta) = @_;
	my @plugins = $self->_load_plugins($self->_modules_to_load);
	my ($opt, $config) = $self->_parse_arguments(1);
	require Dist::Build::Configurator;
	return Dist::Build::Configurator->new(
		meta_info => $meta,
		options   => $opt,
		config    => $config,
		plugins   => \@plugins,
		info_class => $self->info_class,
	);
}

sub _parse_arguments {
	my ($self, $skip_saved) = @_;
	my @argv   = $self->arguments;
	my %env    = $self->environment;
	my $bpl    = $skip_saved ? [] : decode_json(read_file('_build/params'));
	my $action = @argv && $argv[0] =~ / \A \w+ \z /x ? shift @argv : 'build';
	my $rc_opts = read_config();
	my @env = defined $env{PERL_MB_OPT} ? split_like_shell($env{PERL_MB_OPT}) : ();
	my @all_arguments = map { @{$_} } grep { defined } $rc_opts->{'*'}, $bpl, $rc_opts->{$action}, \@env, \@argv;
	GetOptionsFromArray(\@all_arguments, \my %opt, $self->options);
	my $config = ExtUtils::Config->new(delete $opt{config});
	return (\%opt, $config);
}

1;

#ABSTRACT: Configuration and plugin loader
