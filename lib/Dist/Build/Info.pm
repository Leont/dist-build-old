package Dist::Build::Info;

use Moose;
extends 'Build::Graph::Info';

has config => (
	is => 'ro',
	isa => 'ExtUtils::Config',
	required => 1,
);

has meta_info => (
	is => 'ro',
	isa => 'CPAN::Meta',
	required => 1,
);

has options => (
	isa => 'HashRef',
	traits => ['Hash'],
	handles => {
		option => 'get',
		has_option => 'exists',
		options    => 'elements',
	},
);

sub verbose {
	my $self = shift;
	return $self->option('verbose');
}

1;

# ABSTRACT: Node info
