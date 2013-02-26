package Dist::Build::Role::Plugin;

use Moose::Role;
use Moose::Util::TypeConstraints;

role_type 'Dist::Build::Role::Plugin';

has plugin_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has builder => (
	is       => 'ro',
	isa      => 'Dist::Build::Builder',
	required => 1,
	weak_ref => 1,
);

sub mvp_multivalue_args { }
sub mvp_aliases { return {} }

sub configure {
	my ($class, $loader) = @_;
	$loader->add_plugin($class);
	return;
}

1;

__END__

# ABSTRACT: Plugin role
