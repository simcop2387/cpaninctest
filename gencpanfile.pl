#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin.'/lib';

use Dist;

for my $dist (sort keys %Dist::dist_to_mod) {
    printf "requires '%s' => 0\n", $Dist::dist_to_mod{$dist}[0];
}
