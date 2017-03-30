#!/usr/bin/env perl

use 5.24.0;

use Data::Dumper;
use Storable;
#$Data::Dumper::Terse = 1;
print Dumper([keys ((retrieve $ARGV[0])->%*)]);
