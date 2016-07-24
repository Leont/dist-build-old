package Dist::Build;

use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;

use Build::Graph;
use Carp qw/croak carp/;
use CPAN::Meta;
use ExtUtils::Helpers 0.007 qw/split_like_shell detildefy make_executable/;
use ExtUtils::Manifest 'maniread';
use File::Spec::Functions 'catfile';
use Getopt::Long 2.36 qw/GetOptionsFromArray/;
use Parse::CPAN::Meta;

sub load_meta {
	my @files = @_;
	my ($metafile) = grep { -e } @files or croak "No META information provided\n";
	return CPAN::Meta->load_file($metafile, { lazy_validation => 0 });
}

#XXX: hardcoded for now.
my @modules = qw/Core CopyPM TAP DistShare/;

sub read_file {
	my $filename = shift;
	$filename = catfile(@{$filename}) if ref $filename;
	open my $fh, '<:raw', $filename or croak "Could not open $filename: $!";
	my $ret = do { local $/; <$fh> };
	close $fh or croak "Could not read $filename: $!";
	return $ret;
}

my $json_backend = Parse::CPAN::Meta->json_backend;
my $json = $json_backend->new->canonical->pretty->utf8;

sub load_json {
	my $filename = shift;
	return $json->decode(read_file($filename));
}

sub write_file {
	my ($filename, $content) = @_;
	$filename = catfile(@{$filename}) if ref $filename;
	open my $fh, '>:raw', $filename or croak "Could not open $filename: $!";
	print {$fh} $content or croak "Could not write $filename: $!";
	close $fh or croak "Could not write $filename: $!";
	return;
}

sub save_json {
	my ($filename, $content) = @_;
	write_file($filename, $json->encode($content));
	return;
}

sub Build {
	my ($args, $env) = @_;
	my $meta = load_meta('MYMETA.json', 'MYMETA.yml');

	my @options  = qw/config=s% verbose:1 jobs=i install_base=s install_path=s% installdirs=s destdir=s prefix=s/;
	my $pregraph = load_json([qw/_build graph/]);
	my $graph = Build::Graph->load($pregraph, sub {
		my $module = shift;
		push @options, $module->options;
	});

	my ($bpl, $mbopts) = @{ load_json([qw/_build params/]) };
	my %options;
	GetOptionsFromArray($_, \%options, @options) for $bpl, $mbopts, $args;
	my $action = @{$args} ? shift @{$args} : 'build';
	$_ = detildefy($_) for grep { defined } @options{qw/install_base destdir prefix/}, values %{ $options{install_path} };

	require ExtUtils::Config;
	$options{config} = ExtUtils::Config->new($options{config});
	require ExtUtils::InstallPaths;
	$options{install_paths} = ExtUtils::InstallPaths->new(%options, dist_name => $meta->name);

	return $graph->run($action, %options, meta => $meta);
}

sub Build_PL {
	my ($args, $env) = @_;

	my $meta = load_meta('META.json', 'META.yml');

	printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
	my $dir = $meta->name eq 'Dist-Build' ? 'lib' : 'inc';
	write_file('Build', "#!perl\nuse lib '$dir';\nuse Dist::Build;\nBuild(\\\@ARGV, \\\%ENV);\n");
	make_executable('Build');

	my @meta_pieces;
	my $graph = Build::Graph->new;
	$graph->load_commands('Dist::Build::CommandSet::Core');
	my %commands_seen;
	for my $plugin_name (@modules) {
		my $file_name = "Dist/Build/Plugin/$plugin_name.pm";
		require $file_name;
		my $plugin = "Dist::Build::Plugin::$plugin_name"->new();
		my @commandsets = $plugin->commandsets;
		$graph->load_commands($_) for grep { !$commands_seen{$_}++ } @commandsets;
		$plugin->manipulate_graph($graph, $meta);
		push @meta_pieces, $plugin->meta_merge;
	}
	$graph->add_file($_) for sort keys %{ maniread() };

	mkdir '_build' if not -d '_build';
	save_json([qw/_build graph/], $graph->to_hashref);
	my @env = defined $env->{PERL_MB_OPT} ? split_like_shell($env->{PERL_MB_OPT}) : ();
	save_json([qw/_build params/], [ $args, \@env ]);

	if (@meta_pieces) {
		require CPAN::Meta::Merge;
		my $merged = CPAN::Meta::Merge->new(default_version => 2)->merge($meta, @meta_pieces);
		$merged->{dynamic_config} = 0;
		$meta = CPAN::Meta->create($merged, { lazy_validation => 0 });
	}
	$meta->save('MYMETA.json');
	$meta->save('MYMETA.yml', { version => 1.4 });
	return;
}

1;

# ABSTRACT: A modern module builder, author tools not included!
