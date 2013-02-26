package Dist::Build::Loader;
use strict;
use warnings;

use Moose;
use ExtUtils::BuildRC 0.003 qw/read_config/;
use ExtUtils::Helpers 0.007 qw/split_like_shell/;
use File::Slurp qw/read_file/;
use Getopt::Long qw/GetOptionsFromArray/;
use JSON 2 qw/decode_json/;
use Module::Load;

has plugins => (
	isa => 'ArrayRef[Str]',
	traits => [ 'Array' ],
	handles => {
		add_plugin => 'push',
		plugins => 'elements',
	},
	init_arg => undef,
	default => sub { [ ] },
);

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

#XXX: hardcoded for now.
my @modules = qw/Sanity CopyPM TAP Install/;
sub _modules_to_load {
	return @modules;
}

sub _load_modules {
	my $self = shift;
	for my $shortname ($self->_modules_to_load) {
		my $module = "Dist::Build::Plugin::$shortname";
		load($module);
		$module->configure($self);
	}
	return;
}

sub create_builder {
	my ($self, $meta) = @_;
	$self->_load_modules;
	my ($opt, $config) = $self->_parse_arguments;
	require Dist::Build::Builder;
	my $builder = Dist::Build::Builder->new(
		meta_info => $meta,
		options   => $opt,
		config    => $config,
	);
	for my $plugin ($self->plugins) {
		my $instance = $plugin->new(plugin_name => $plugin, builder => $builder);
		$builder->add_plugin($instance);
	}
	return $builder;
}

sub create_configurator {
	my ($self, $meta) = @_;
	$self->_load_modules;
	my ($opt, $config) = $self->_parse_arguments(1);
	require Dist::Build::Configurator;
	my $configurator = Dist::Build::Configurator->new(
		meta_info => $meta,
		options   => $opt,
		config    => $config,
	);
	for my $plugin ($self->plugins) {
		$configurator->add_plugin($plugin);
	}
	return $configurator;
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
