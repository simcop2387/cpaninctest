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
use Storable;

use Module;
use CpanFile;
use TestCpanInc;

my $opt_cpanfile;
my $opt_module;
my $opt_help;
my $opt_jobstor='';

GetOptions ("module=s" => \$opt_module,
            "cpanfile=s"   => \$opt_cpanfile,      # string
            "perlbrew_env=s" => \$TestCpanInc::perlbrew_env,
            "jobstor=s" => \$opt_jobstor,
            "help"  => \$opt_help);   # flagV

if ((!$opt_module && !$opt_cpanfile) || ($opt_module && $opt_cpanfile) || $opt_help) {
    print "Call with either --cpanfile xor --module to specify what to test.\n",
          "Use --perlbrew_env to specify which perl install to use, defaults to blead\n";
    exit(1);
}

$|++;

my @modules;
my %jobstatus;

if (!-e $opt_jobstor) {
    my @mods_to_test = ($opt_module);

    if ($opt_cpanfile) {
    # TODO read cpanfile, via do/require
        cpanfile::__parse_file($opt_cpanfile);
        @mods_to_test = @cpanfile::mods;
    }

    print "Building dep list sorry, this'll take a while\n";
    for my $mtt (@mods_to_test) {
        my $mod = Module->new_module($mtt);
        push @modules, map {$_->name} uniq TestCpanInc::dep_order($mod);
    }
    print "\n";
    @modules = uniq(@modules);
} else {
    my $data = retrieve($opt_jobstor);
    @modules = $data->{modules}->@*;
    %jobstatus = $data->{jobstatus}->%*;
}

sub __save_cache {
    if ($opt_jobstor) {
        store {modules => \@modules, jobstatus => \%jobstatus}, $opt_jobstor;
    }
};
END {__save_cache};


for my $mod (@modules) {
    print "Testing $mod\n";
    unless ($jobstatus{$mod}{tested}) {
        my $status = TestCpanInc::test_module($mod);
        $jobstatus{$mod}{tested} = 1;
        $jobstatus{$mod}{status} = $status;
        __save_cache;
    }
}
