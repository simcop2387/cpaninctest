#!/usr/bin/env perl

use 5.24.0;

use Data::Dumper;
use Storable;
#$Data::Dumper::Terse = 1;

my $cache = retrive $ARGV[0];

for my $key (keys $cache->%*) {
  if ($key =~ /OurNet/) {
    delete $cache->{$key};
  }
}

print Dumper([keys ((retrieve $ARGV[0])->%*)]);
