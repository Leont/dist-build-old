package Dist::Build::Configurator;

use Moose;

use ExtUtils::Helpers 0.007 qw/make_executable split_like_shell build_script/;
use File::Slurp qw/read_file write_file/;
use JSON 2 qw/encode_json/;

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
	isa => 'ArrayRef[Str]',
	traits => [ 'Array' ],
	handles => {
		plugins    => 'elements',
		add_plugin => 'push',
	},
	default => sub { [] },
);

sub write_buildscript {
	my ($self, $arguments) = @_;
	my $meta = $self->meta_info;

	printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
	my $dir = $meta->name eq 'Dist-Build' ? 'lib' : 'inc';
	write_file('Build', "#!perl\nuse lib '$dir';\nuse Dist::Build;\nBuild(\@ARGV);\n");
	make_executable('Build');

	mkdir '_build' if not -d '_build';
	write_file(qw{_build/params}, encode_json($arguments));
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
