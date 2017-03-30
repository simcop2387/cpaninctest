#!/usr/bin/env perl

use Data::Dumper;
use Storable;

print Dumper(retrieve $ARGV[0]);
