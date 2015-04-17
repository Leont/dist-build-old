package Dist::Build::Plugin::DistShare;

use strict;
use warnings;

use parent qw/Dist::Build::Role::Plugin/;

use File::Spec::Functions qw/catfile abs2rel/;

sub get_trans {
	return {
		'to-share' => sub {
			my ($source, $distname) = @_;
			return catfile(qw/blib lib auto share dist/, $distname, abs2rel($source, 'share'));
		},
	};
}

sub manipulate_graph {
	my ($self, $meta) = @_;

	$self->add_wildcard('dist-share-source', dir => 'share', pattern => '*');
	$self->add_subst('dist-share', 'dist-share-source',
		trans  => [ 'to-share', '$(source)', $meta->name ],
		action => [ 'Core/copy', '%(verbose)', '$(source)', '$(target)' ],
	);
	$self->add_phony('distshare', dependencies => ['@(dist-share)'], add_to => 'build-elements');

	return;
}

1;

#ABSTRACT: Distribution sharefiles
