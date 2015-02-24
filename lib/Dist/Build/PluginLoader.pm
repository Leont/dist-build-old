package Dist::Build::PluginLoader;

use strict;
use warnings;

use parent 'Build::Graph::Role::Loader';

sub new {
	my ($class, %arguments) = @_;
	my $self = $class->SUPER::new(%arguments);
	$self->{loaded} = {};
	$self->{with}   = {};
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
	my ($self, $module, %args) = @_;
	my $name = $args{name};
	return $self->{loaded}{$module} ||= do {
		$module =~ s/ ^ - /Dist::Build::Plugin::/xms;
		$self->load_module($module);
		my $plugin = $module->new(%args);
		$self->graph->plugins->add_plugin($name, $plugin);
		$self->_match_plugin($name, $plugin);
		$plugin;
	}
}

sub _match_plugin {
	my ($self, $name, $plugin, %args) = @_;
	for my $matcher (keys %{ $self->{with} }) {
		if ($plugin->isa($matcher)) {
			$self->{with}{$matcher}->($name, $plugin, %args);
		}
	}
	return;
}

1;

# ABSTRACT: An extension instance loader for Build::Graph
