package Dist::Build::Role::Plugin;

use Moo::Role;

has name => (
	is       => 'ro',
	required => 1,
);

sub configure {
}

1;

# ABSTRACT: Plugin role
