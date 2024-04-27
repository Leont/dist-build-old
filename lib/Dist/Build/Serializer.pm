package Dist::Build::Serializer;

use strict;
use warnings;

use parent 'ExtUtils::Builder::Serializer';

use List::Util 1.33 'any';

use ExtUtils::Builder::Action::Function;
use Dist::Build::Core;

sub serialize_action {
	my ($self, $action, %args) = @_;

	if ($action->isa('ExtUtils::Builder::Action::Function') && $action->module eq 'Dist::Build::Core') {
		return [ $action->function, $action->arguments ];
	} else {
		return $self->SUPER::serialize_action($action);
	}
}

sub deserialize_action {
	my ($self, $serialized, %options) = @_;
	my ($command, @args) = @{$serialized};

	if ($command eq 'tap_harness') {
		my %args = @args;
		$args{verbose} = $options{verbose} if defined $options{verbose};
		$args{jobs} = $options{jobs} if defined $options{jobs};
		return make_function('tap_harness', %args);
	} elsif ($command eq 'copy') {
		my ($source, $destination, %args) = @args;
		$args{verbose} = $options{verbose} if defined $options{verbose};
		return make_function('copy', $source, $destination, %args);
	} elsif ($command eq 'mkdir') {
		my ($destination, %args) = @args;
		$args{verbose} = $options{verbose} if defined $options{verbose};
		return make_function('mkdir', $destination, %args);
	} elsif ($command eq 'install') {
		my %args = @args;
		$args{verbose} = $options{verbose} if defined $options{verbose};
		$args{uninst} = $options{uninst} if defined $options{uninst};
		$args{install_map} = $options{install_paths}->install_map;
		return make_function('install', %args);
	} elsif (any { $command eq $_ } @Dist::Build::Core::EXPORT_OK) {
		return make_function($command, @args);
	} else {
		$self->SUPER::deserialize_action($serialized, %options);
	}
}

sub make_function {
	my ($command, @args) = @_;
	ExtUtils::Builder::Action::Function->new(
		function  => $command,
		module    => 'Dist::Build::Core',
		arguments => \@args,
		exports   => 'explicit',
	);
}

1;

# ABSTRACT: A Serializer for a Dist::Build plan

=head1 DESCRIPTION

This is a subclass of L<ExtUtils::Builder::Serializer|ExtUtils::Builder::Serializer> that optimizes the serialization of C<Dist::Build> actions such as those in L<Dist::Build::Core>.
