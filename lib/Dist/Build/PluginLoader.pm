package Dist::Build::PluginLoader;

use Moo;
with 'Build::Graph::Role::Loader';

use Module::Runtime;

has _loaded => (
	is       => 'ro',
	default  => sub { {} },
);

has _with => (
	is       => 'ro',
	init_arg => undef,
	default  => sub { {} },
);

sub add_handler {
	my ($self, $name, $callback) = @_;
	(my $full = $name) =~ s/ ^ - /Dist::Build::Role::/xms;
	$self->_with->{$full} = $callback;
	for my $plugin (keys %{ $self->_loaded }) {
		if ($plugin->does($full)) {
			$callback->($self->graph, $plugin);
		}
	}
	return;
}

sub load {
	my ($self, $plugin) = @_;
	return $self->_loaded->{$plugin} ||= $self->_load_plugin($plugin);
}

sub _load_plugin {
	my ($self, $plugin) = @_;
	(my $module = $plugin) =~ s/ ^ - /Dist::Build::Plugin::/xms;
	Module::Runtime::require_module($module);
	$module->configure;
	my $ret = $module->new(name => $plugin, graph => $self->graph);
	$self->_match_plugin($ret);
	return $ret;
}

sub _match_plugin {
	my ($self, $plugin) = @_;
	for my $matcher (keys %{ $self->_with }) {
		if ($plugin->does($matcher)) {
			$self->_with->{$matcher}->($self->graph, $plugin);
		}
	}
}

1;

# ABSTRACT: An extension instance loader for Build::Graph
