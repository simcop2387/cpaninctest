#!/usr/bin/env perl

use lib './lib';
use strict;

use Dist;
use Storable;
use Time::HiRes qw/time/;
use DateTime;

my $dists = 0+%Dist::dist_to_mod;

my $start_time = time();
my $start_dt = DateTime->now();
my $cache = retrieve 'modcache.stor';
my $first_count = 0+$cache->%*;

while (1) {
  sleep(2);
  my $cache = eval {retrieve 'modcache.stor'};
  next unless $cache;
  my $count = 0+$cache->%*;

  my $rate = ($count-$first_count)/(time()-$start_time);
  my $tocomplete = ($dists-$count)/($rate + 0.0000000001);
  my $final_dt = $start_dt->clone()->add(seconds => $tocomplete);
  printf "%d/%d [%02.2f%%] %0.2f/s %s\n", $count, $dists, 100*$count/$dists, $rate, $final_dt->iso8601;
 
};
