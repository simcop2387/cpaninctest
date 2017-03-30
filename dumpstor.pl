#!/usr/bin/env perl

use Data::Dumper;
use Storable;
#$Data::Dumper::Terse = 1;

print Dumper(retrieve $ARGV[0]);
