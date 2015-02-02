package Dist::Build::PluginLoader;

use strict;
use warnings;

use parent 'Build::Graph::ClassLoader';

sub new {
	my ($class, %arguments) = @_;
	my $self = $class->SUPER::new(%arguments);
	$self->{loaded} = {},
	$self->{with}   = {},
	return $self;
}

sub add_handler {
	my ($self, $name, $callback) = @_;
	(my $full = $name) =~ s/ ^ - /Dist::Build::Role::/xms;
	$self->{with}{$full} = $callback;
	for my $plugin (keys %{ $self->{loaded} }) {
		if ($plugin->isa($full)) {
			$callback->($self->graph, $plugin);
		}
	}
	return;
}

sub load {
	my ($self, $plugin) = @_;
	return $self->{loaded}{$plugin} ||= $self->_load_plugin($plugin);
}

sub _load_plugin {
	my ($self, $plugin) = @_;
	(my $module = $plugin) =~ s/ ^ - /Dist::Build::Plugin::/xms;
	$self->SUPER::load($module);
	$module->configure;
	my $ret = $module->new(name => $plugin, graph => $self->graph);
	$self->_match_plugin($ret);
	return $ret;
}

sub _match_plugin {
	my ($self, $plugin) = @_;
	for my $matcher (keys %{ $self->{with} }) {
		if ($plugin->isa($matcher)) {
			$self->{with}{$matcher}->($self->graph, $plugin);
		}
	}
}

1;

# ABSTRACT: An extension instance loader for Build::Graph
