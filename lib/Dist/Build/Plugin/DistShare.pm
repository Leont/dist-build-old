package Dist::Build::Plugin::DistShare;

use strict;
use warnings;

use base qw/Dist::Build::Role::Plugin/;

sub manipulate_graph {
	my ($self, $graph, $meta) = @_;

	$graph->add_pattern('dist-share-source', dir => 'share', pattern => '*');
	$graph->add_subst('dist-share', 'dist-share-source',
		trans_list  => [
			[ 'abs2rel', '$source', 'share', '$dist-name' ],
			[ 'prepend-dirs', qw/blib lib auto share dist $dist-name $source/ ],
		],
		action      => [ 'copy', '%verbose', '$source', '$target' ],
	);
	$graph->add_phony('distshare', dependencies => ['@dist-share'], add_to => 'build-elements');

	return;
}

1;

#ABSTRACT: Distribution sharefiles
