package Dist::Build::Loader;

use Moose;

use Build::Graph;
use ExtUtils::BuildRC 0.003 qw/read_config/;
use ExtUtils::Config;
use ExtUtils::Helpers 0.007 qw/split_like_shell/;
use File::Slurp qw/read_file/;
use Getopt::Long qw/GetOptionsFromArray/;
use JSON 2 qw/decode_json/;
use Module::Runtime qw/require_module/;

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

sub _load_plugin {
	my ($self, $plugin) = @_;
	(my $module = $plugin) =~ s/ ^ - /Dist::Build::Plugin::/xms;
	require_module($module);
	$module->configure($self);
	return $module;
}

sub create_builder {
	my ($self, $meta, $args, $env) = @_;
	my $pregraph   = decode_json(read_file(q{_build/graph}));
	my $commandset = Build::Graph::CommandSet->new;
	my @options    = qw/config=s% verbose:1/;
	for my $dependency (@{ $pregraph->{dependencies} }) {
		my $module = $self->_load_plugin($dependency);
		my $plugin = $module->new(name => $dependency);
		$plugin->configure_commands($commandset) if $plugin->does('Build::Graph::Role::Command');
		push @options, $plugin->options if $plugin->does('Dist::Build::Role::OptionProvider');
	}
	my ($action, $opt, $config) = $self->_parse_arguments($args, $env, \@options);
	my $graph = Build::Graph->new(commands => $commandset, info_class => $self->info_class);
	$graph->load_from_hashref($pregraph->{graph});
	require Dist::Build::Builder;
	return Dist::Build::Builder->new(
		meta_info => $meta,
		options   => $opt,
		config    => $config,
		action    => $action,
		graph     => $graph,
	);
}

sub create_configurator {
	my ($self, $meta) = @_;
	my @plugins = map { $self->_load_plugin($_)->new(name => $_) } $self->_modules_to_load;
	require Dist::Build::Configurator;
	return Dist::Build::Configurator->new(
		meta_info  => $meta,
		plugins    => \@plugins,
		info_class => $self->info_class,
	);
}

sub _parse_arguments {
	my ($self, $args, $env, $options) = @_;
	my $bpl     = decode_json(read_file('_build/params'));
	my $action  = @{$args} && $args->[0] =~ / \A \w+ \z /xms ? shift @{$args} : 'build';
	my $rc_opts = read_config();
	my @env     = defined $env->{PERL_MB_OPT} ? split_like_shell($env->{PERL_MB_OPT}) : ();
	my @all     = map { @{$_} } grep { defined } $rc_opts->{'*'}, $bpl, $rc_opts->{$action}, \@env, $args;
	GetOptionsFromArray(\@all, \my %opt, @{$options});
	my $config = ExtUtils::Config->new(delete $opt{config});
	return ($action, \%opt, $config);
}

1;

#ABSTRACT: Configuration and plugin loader
