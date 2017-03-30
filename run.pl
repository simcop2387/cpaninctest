#!/usr/bin/env perl
use 5.22.0;

use FindBin;
use lib $FindBin::Bin.'/lib';

use strict;
use autodie;
use warnings;
use Data::Dumper;
use Getopt::Long;
use List::Util qw/uniq/;

use Module;
use CpanFile;
use TestCpanInc;

our $opt_cpanfile;
our $opt_module;
our $opt_help;

GetOptions ("module=s" => \$opt_module,
            "cpanfile=s"   => \$opt_cpanfile,      # string
            "perlbrew_env=s" => \$TestCpanInc::perlbrew_env,
            "help"  => \$opt_help);   # flagV

if ((!$opt_module && !$opt_cpanfile) || ($opt_module && $opt_cpanfile) || $opt_help) {
    print "Call with either --cpanfile xor --module to specify what to test.\n",
          "Use --perlbrew_env to specify which perl install to use, defaults to blead\n";
    exit(1);
}

$|++;

my @mods_to_test = ($opt_module);

if ($opt_cpanfile) {
# TODO read cpanfile, via do/require
    cpanfile::__parse_file($opt_cpanfile);
    @mods_to_test = @cpanfile::mods;
}

my @modules;

print "Building dep list sorry, this'll take a while\n";
for my $mtt (@mods_to_test) {
    my $mod = Module->new_module($mtt);
    push @modules, map {$_->name} uniq TestCpanInc::dep_order($mod);
}

print "\n";
@modules = uniq(@modules);

for my $mod (@modules) {
    print "Testing $mod\n";
    TestCpanInc::test_module($mod);
}
