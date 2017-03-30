package TestCpanInc;
use 5.22.0;

use strict;
use autodie;
use warnings;
use Data::Dumper;
use List::Util qw/uniq/;
use IPC::Run qw/run/;

our $perlbrew_env = 'blead';

sub dep_order {
    my $module = shift;

    my @orders;

    for my $dep ($module->depends->@*) {
        print "\r", $dep->name, "         ";
        push @orders, dep_order($dep);
    }

    push @orders, $module;

    return @orders;
}

sub run_cpanm {
    my ($module, $incstatus) = @_;

    $ENV{PERL_USE_UNSAFE_INC} = !!$incstatus;
    my @cmd = (qw/perlbrew exec --with/, $perlbrew_env, qw|cpanm --reinstall --verbose --mirror http://cpan.simcop2387.info/ |, $module);

    my $out;
    run \@cmd, '>&', \$out;

    my $exitcode = $?;

    return ($exitcode, $out);
}

sub test_module {
    my $module = shift;
    my ($ret, $noincout) = run_cpanm($module, 0);

    if ($ret) {
        my ($ret2, $incout) = run_cpanm($module, 1);

        if (!$ret2) {
            print ">>>>Module $module failed to build without UNSAFE INC\n";
            open(my $fh, ">", "logs/${$}_${module}_incfailure.log");
            print $fh $noincout;
        } else {
            print "<<<<Module $module fails to build entirely\n";

            open(my $fh, ">", "logs/${$}_${module}_genfailure.log");
            print $fh $incout;
        }
    }
}
