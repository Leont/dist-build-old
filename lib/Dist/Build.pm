package Dist::Build;

use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;

use Build::Graph;
use Carp qw/croak carp/;
use CPAN::Meta;
use CPAN::Meta::Check qw/verify_dependencies/;
use ExtUtils::Config;
use ExtUtils::Helpers 0.007 qw/split_like_shell make_executable/;
use File::Slurp::Tiny qw/read_file write_file/;
use Getopt::Long qw/GetOptionsFromArray/;
use JSON 2 qw/encode_json decode_json/;

use Dist::Build::PluginLoader;

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

sub _parse_arguments {
	my ($args, $env, $options) = @_;
	my $bpl     = decode_json(read_file('_build/params'));
	my $action  = @{$args} && $args->[0] =~ / \A \w+ \z /xms ? shift @{$args} : 'build';
	my @env     = defined $env->{PERL_MB_OPT} ? split_like_shell($env->{PERL_MB_OPT}) : ();
	GetOptionsFromArray([ @{$bpl}, @env, @{$args} ], \my %opt, @{$options});
	my $config = ExtUtils::Config->new(delete $opt{config});
	return ($action, \%opt, $config);
}

sub Build {
	my ($args, $env) = @_;
	my $meta = load_meta('MYMETA.json', 'MYMETA.yml');

	my $pregraph = decode_json(read_file(q{_build/graph}));
	my @options  = qw/config=s% verbose:1 install_base=s install_path=s% installdirs=s destdir=s prefix=s/;

	my $graph = Build::Graph->load($pregraph);
	$graph->loader->add_handler('Dist::Build::Role::Options', sub {
		my ($graph, $module) = @_;
		push @options, $module->options;
	});

	my ($action, $options, $config) = _parse_arguments($args, $env, \@options);
	return $graph->run($action, options => $options, config => $config, meta_info => $meta);
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

	my $graph = Build::Graph->new(info_class => $info_class, loader_class => 'Dist::Build::PluginLoader');
	$graph->loader->add_handler('-Graph::CommandProvider' => sub {
		my ($graph, $module) = @_;
		$module->configure_commands($graph->commandset);
	});
	$graph->loader->add_handler('-Graph::Manipulator', sub {
		my ($graph, $module) = @_;
		$module->manipulate_graph($graph);
	});
	$graph->loader->load($_) for _modules_to_load();
	write_file(qw{_build/graph}, JSON->new->canonical->pretty->encode($graph->to_hashref));

	$meta->save('MYMETA.json');
	$meta->save('MYMETA.yml', { version => 1.4 });
	return;
}

1;

# ABSTRACT: A modern module builder, author tools not included!
