package Dist::Build::Role::Plugin;

use Moose::Role;
use Moose::Util::TypeConstraints;

role_type 'Dist::Build::Role::Plugin';

has plugin_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

sub configure {
}

1;

# ABSTRACT: Plugin role
