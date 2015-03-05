package Dist::Build::Plugin::DistShare;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin/;

use File::Spec::Functions qw/catfile abs2rel/;

sub _get_commands {
	return {};
}

sub _get_substs {
	return {
		'to-share' => sub {
			my ($source, $distname) = @_;
			return catfile(qw/blib lib auto share dist/, $distname, abs2rel($source, 'share'));
		},
	};
}

sub manipulate_graph {
	my ($self, $graph) = @_;

	$graph->add_phony('distshare', dependencies => ['@(dist-share)']);
	$graph->get_node('build')->add_dependencies('distshare');

	my $shared = $graph->add_wildcard('dist-share-source', dir => 'share', pattern => '*');
	$graph->add_subst('dist-share', $shared,
		subst  => [ 'DistShare/to-share', '$(source)', '@(distname)' ],
		action => [ 'Core/copy', '%(verbose)', '$(source)', '$(target)' ],
	);
	return;
}

1;

#ABSTRACT: Distribution sharefiles
