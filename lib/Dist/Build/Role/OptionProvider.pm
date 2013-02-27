package Dist::Build::Role::OptionProvider;

use Moo::Role;

with 'Dist::Build::Role::Plugin';

requires 'options';

1;

# ABSTRACT: Role that describes command line options
