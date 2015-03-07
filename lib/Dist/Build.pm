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
use Getopt::Long qw/GetOptionsFromArray/;
use JSON::PP 2 qw/encode_json decode_json/;

sub load_meta {
	my @files = @_;
	my ($metafile) = grep { -e } @files or croak "No META information provided\n";
	return CPAN::Meta->load_file($metafile, { lazy_validation => 0 });
}

#XXX: hardcoded for now.
my @modules = qw/Core CopyPM TAP Install DistShare/;

sub _modules_to_load {
	return @modules;
}

sub parse_arguments {
	my ($args, $options) = @_;
	my ($bpl, $env) = @{ decode_json(read_file([qw/_build params/])) };
	my $action = @{$args} && $args->[0] =~ / \A \w+ \z /xms ? shift @{$args} : 'build';
	my %opt;
	GetOptionsFromArray($_, \%opt, @{$options}) for $bpl, $env, $args;
	$_ = detildefy($_) for grep { defined } @opt{qw/install_base destdir prefix/}, values %{ $opt{install_path} };
	require ExtUtils::Config;
	$opt{config} = ExtUtils::Config->new($opt{config});
	return ($action, \%opt);
}

sub read_file {
	my $filename = shift;
	$filename = catfile(@{$filename}) if ref $filename;
	open my $fh, '<:raw', $filename or croak "Could not open $filename: $!";
	my $ret = do { local $/; <$fh> };
	close $fh or croak "Could not read $filename: $!";
	return $ret;
}

sub write_file {
	my ($filename, $content) = @_;
	$filename = catfile(@{$filename}) if ref $filename;
	open my $fh, '>:raw', $filename or croak "Could not open $filename: $!";
	print {$fh} $content or croak "Could not write $filename: $!";
	close $fh or croak "Could not write $filename: $!";
	return;
}

sub Build {
	my ($args, $env) = @_;
	my $meta = load_meta('MYMETA.json', 'MYMETA.yml');

	my @options  = qw/config=s% verbose:1 jobs=i install_base=s install_path=s% installdirs=s destdir=s prefix=s/;
	my $pregraph = decode_json(read_file([qw/_build graph/]));
	my $graph = Build::Graph->load($pregraph);
	$graph->add_plugin_handler(sub {
		my ($module) = @_;
		push @options, $module->options;
	});

	my ($action, $options) = parse_arguments($args, \@options);

	require ExtUtils::InstallPaths;
	$options->{install_paths} = ExtUtils::InstallPaths->new(%{$options}, dist_name => $meta->name);

	return $graph->run($action, %{$options}, meta => $meta);
}

sub Build_PL {
	my @args = @_;

	my $meta = load_meta('META.json', 'META.yml');

	printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
	my $dir = $meta->name eq 'Dist-Build' ? 'lib' : 'inc';
	write_file('Build', "#!perl\nuse lib '$dir';\nuse Dist::Build;\nBuild(\\\@ARGV, \\\%ENV);\n");
	make_executable('Build');

	my @meta_pieces;
	my $graph = Build::Graph->new;
	$graph->add_variable('distname', $meta->name);
	$graph->add_plugin_handler(sub {
		my ($module) = @_;
		$module->manipulate_graph($graph);
		push @meta_pieces, $module->meta_merge;
	});
	$graph->load_plugin($_, "Dist::Build::Plugin::$_") for _modules_to_load();
	$graph->match(keys %{ maniread() });

	mkdir '_build' if not -d '_build';
	write_file([qw/_build graph/], JSON::PP->new->canonical->pretty->encode($graph->to_hashref));
	my @env = defined $ENV{PERL_MB_OPT} ? split_like_shell($ENV{PERL_MB_OPT}) : ();
	write_file([qw/_build params/], encode_json([ \@args, \@env ]));

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
