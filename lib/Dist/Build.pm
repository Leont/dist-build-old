package Dist::Build;
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;

use Build::Graph;
use Carp qw/croak carp/;
use CPAN::Meta;
use CPAN::Meta::Check qw/verify_dependencies/;
use ExtUtils::BuildRC 0.003 qw/read_config/;
use ExtUtils::Config;
use ExtUtils::Helpers 0.007 qw/split_like_shell make_executable/;
use File::Slurp qw/read_file write_file/;
use Getopt::Long qw/GetOptionsFromArray/;
use JSON 2 qw/encode_json decode_json/;
use List::MoreUtils qw/uniq/;
use Module::Runtime qw/require_module/;

sub load_meta {
	my @files = @_;
	my ($metafile) = grep { -e $_ } @files or croak "No META information provided\n";
	return CPAN::Meta->load_file($metafile);
}

#XXX: hardcoded for now.
my @modules    = qw/-Sanity -CopyPM -TAP -Install/;
my $info_class = 'Dist::Build::Info';

sub _modules_to_load {
	return @modules;
}

sub _load_plugin {
	my $plugin = shift;
	(my $module = $plugin) =~ s/ ^ - /Dist::Build::Plugin::/xms;
	require_module($module);
	$module->configure;
	return $module;
}

sub _parse_arguments {
	my ($args, $env, $options) = @_;
	my $bpl     = decode_json(read_file('_build/params'));
	my $action  = @{$args} && $args->[0] =~ / \A \w+ \z /xms ? shift @{$args} : 'build';
	my $rc_opts = read_config();
	my @env     = defined $env->{PERL_MB_OPT} ? split_like_shell($env->{PERL_MB_OPT}) : ();
	my @all     = map { @{$_} } grep { defined } $rc_opts->{'*'}, $bpl, $rc_opts->{$action}, \@env, $args;
	GetOptionsFromArray(\@all, \my %opt, @{$options});
	my $config = ExtUtils::Config->new(delete $opt{config});
	return ($action, \%opt, $config);
}

sub Build {
	my ($args, $env) = @_;
	my $meta = load_meta('MYMETA.json', 'MYMETA.yml');

	my $pregraph = decode_json(read_file(q{_build/graph}));
	my @options  = qw/config=s% verbose:1/;

	my @commands;
	for my $dependency (@{ $pregraph->{dependencies} }) {
		my $module = _load_plugin($dependency);
		my $plugin = $module->new(name => $dependency);
		push @commands, $plugin->configure_commands if $plugin->does('Build::Graph::Role::CommandProvider');
		push @options,  $plugin->options            if $plugin->does('Dist::Build::Role::OptionProvider');
	}
	my $commandset = Build::Graph::CommandSet->new(commands => { map { %{$_} } @commands });
	my $graph = Build::Graph->new(commands => $commandset, info_class => $info_class, nodes => $pregraph->{graph});

	my ($action, $options, $config) = _parse_arguments($args, $env, \@options);
	return $graph->run($action, options => $options, config => $config, meta_info => $meta);
}

sub plugins_with {
	my ($role, @plugins) = @_;
	$role =~ s/ ^ - /Dist::Build::Role::/xms;
	return grep { $_->does($role) } @plugins;
}

sub Build_PL {
	my @args = @_;

	my $meta = load_meta('META.json', 'META.yml');
	my @carp = verify_dependencies($meta, 'configure', 'requires');
	carp join "\n", @carp if @carp;

	printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
	my $dir = $meta->name eq 'Dist-Build' ? 'lib' : 'inc';
	write_file('Build', "#!perl\nuse lib '$dir';\nuse Dist::Build;\nBuild(\\\@ARGV, \\\%ENV);\n");
	make_executable('Build');

	mkdir '_build' if not -d '_build';
	write_file(qw{_build/params}, encode_json(\@args));

	my @plugins = map { _load_plugin($_)->new(name => $_) } _modules_to_load();
	my @dependencies = uniq(map { $_->dependencies } plugins_with(-Graph::Manipulator, @plugins));
	my %commands = map { %{$_} } map { $_->configure_commands } plugins_with(-Graph::CommandProvider, @plugins);
	my $commandset = Build::Graph::CommandSet->new(commands => \%commands);
	my $graph = Build::Graph->new(commands => $commandset, info_class => $info_class);
	for my $grapher (plugins_with(-Graph::Manipulator, @plugins)) {
		$grapher->manipulate_graph($graph);
	}
	write_file(qw{_build/graph}, encode_json({ dependencies => \@dependencies, graph => $graph->nodes_to_hashref }));

	$meta->save('MYMETA.json');
	$meta->save('MYMETA.yml', { version => 1.4 });
	return;
}

1;

# ABSTRACT: A modern module builder, author tools not included!
