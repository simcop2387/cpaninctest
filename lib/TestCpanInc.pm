package TestCpanInc;
use 5.22.0;

use strict;
use autodie;
use warnings;
use Data::Dumper;
use List::Util qw/uniq/;
use IPC::Run qw/run/;
use Module;

our $perlbrew_env = 'blead';

sub remove_imc {
    my ($module, $incstatus) = @_;

    $ENV{PERL_USE_UNSAFE_INC} = 1;
    my @cmd = (qw/perlbrew exec --with/, $perlbrew_env, qw|cpanm --force --uninstall inc::Module::Install |);

    my $out;
    run \@cmd, '>&', \$out;
}

our $last_dep = time();
our @total_deps = ();

sub dep_order {
    my $module = shift;
    my $level = shift || 0;

    my @orders;

    for my $dep ($module->depends->@*) {
	
	if (time() - $last_dep >= 10  || $level >= 200) {
        	print $dep->name," ",$dep->dist, " " ,$level, "\n";
		$last_dep = time();
	}

	next if (Module::_is_banned($dep->name));
	next if ($dep->dist ~~ @total_deps); # skip it if we've already added this to the total deps
	push @total_deps, $dep->dist;
        push @orders, dep_order($dep, $level+1);
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
    remove_imc();
    my ($ret, $noincout) = run_cpanm($module, 0);

    if ($ret) {
        remove_imc();
        my ($ret2, $incout) = run_cpanm($module, 1);

        if (!$ret2) {
            print ">>>>Module $module failed to build without UNSAFE INC\n";
            open(my $fh, ">", "logs/${module}_incfailure.log");
            print $fh $noincout;

            return "inc failed";
        } else {
            print "<<<<Module $module fails to build entirely\n";

            open(my $fh, ">", "logs/${module}_genfailure.log");
            print $fh $incout;

            return "gen failed";
        }
    }

    return "success";
}

1;
