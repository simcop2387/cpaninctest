package Dists;
use strict;
use warnings;
use Data::Dumper;

our %dist_to_mod;
our %mod_to_dist;

open(my $fh, "<", "02packages.details.txt");

while (my $l = <$fh>) {
    chomp $l;
    my ($module, $version, $dist) = split(' ', $l,3);

    push $dist_to_mod{$dist}->@*, $module;
    $mod_to_dist{$module} = $dist;
}

print Dumper(\%dist_to_mod);

1;
