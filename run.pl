#!/usr/bin/env perl
use 5.22.0;

package Module;
use Moose;
use Module::CoreList;
use Storable;

has 'name' => (is => 'ro');
has 'version' => (is => 'ro');

has 'depends' => (
    builder => 'get_deps',
    is => 'ro',
    isa => 'ArrayRef[Module]',
    lazy => 1,
);

our %cache;
if (-e 'cache.stor') {
    eval {
      my $cache_href=retrieve('cache.stor');
      %cache = $cache_href->%*;
    };
    if ($@) {
        print STDERR "Couldn't load cache $@\n";
    }
}

END {
 store \%cache, 'cache.stor';
};

sub new_module {
    my $class = shift;
    my $module = shift;
    chomp $module;
    my ($name, $version) = split (/[\-~]/, $module);

    return $cache{$name} if exists $cache{$name};

    $cache{$name} = Module->new(name => $name);
}

sub _is_core {
    my $module = shift;
    chomp $module;
    my ($name, $version) = split (/[\-~]/, $module);

    my $ret = ($name eq 'perl' || Module::CoreList->first_release($name)) // 0;

    return $ret;
}

sub get_deps {
    my $self=shift;
    my $module = $self->name;

    # skip perl, or core modules
    return [] if _is_core($module);

    open(my $ph, "-|", qw/cpanm --quiet --showdeps/, $module);

    return [map {Module->new_module($_)} grep {!_is_core($_)} <$ph>];
}

sub print_deps {
    my ($self, $level, $v) = @_;

    for my $dep ($self->depends->@*) {
        my $name = $dep->name;
        print ((" " x $level), $name, "\n");
        $dep->print_deps($level+1, [@$v, $name]) unless ($name ~~ @$v);
    }
}

package cpanfile;
# HACK since cpan files are valid perl, i'm just using do/require

our @mods;

sub __parse_file {
    my $file = shift;

    require $file;
}

sub requires {
    push @mods, $_[0];
}

sub recommends {
    push @mods, $_[0];
}

sub conflicts {} # IGNORE These

# we expect all types
sub on {
    my ($env, $code) = @_;
    $code->();
}

sub feature {
    my ($feat, $desc, $code) = @_;
    $code->();
}

package main;
use strict;
use autodie;
use warnings;
use Data::Dumper;
use List::Util qw/uniq/;
use IPC::Run qw/run/;
use Getopt::Long;

our $opt_perlbrew_env='blead';
our $opt_module;
our $opt_cpanfile;
our $opt_help;

GetOptions ("module=s" => \$opt_module,
            "cpanfile=s"   => \$opt_cpanfile,      # string
            "perlbrew_env=s" => \$opt_perlbrew_env,
            "help"  => \$opt_help);   # flagV

if ((!$opt_module && !$opt_cpanfile) || ($opt_module && $opt_cpanfile) || $opt_help) {
    usage(); exit(1);
}

sub usage {
    print "Call with either --cpanfile xor --module to specify what to test.\n",
          "Use --perlbrew_env to specify which perl install to use, defaults to blead\n";
}

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
    my @cmd = (qw/perlbrew exec --with/, $opt_perlbrew_env, qw/cpanm --reinstall --verbose/, $module);

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

sub main {
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
        push @modules, map {$_->name} uniq dep_order($mod);
    }

    @modules = uniq(@modules);

    for my $mod (@modules) {
        print "Testing $mod\n";
        test_module($mod);
    }
}

main();
