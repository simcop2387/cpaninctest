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

use strict;
use autodie;
use warnings;
use Data::Dumper;
use List::Util qw/uniq/;

sub dep_order {
    my $module = shift;

    my @orders;

    for my $dep ($module->depends->@*) {
        push @orders, dep_order($dep);
    }

    push @orders, $module;

    return @orders;
}

my $foo = Module->new_module('Moose');
$foo->print_deps(0, []);

print Dumper([map {$_->name} uniq dep_order($foo)]);
