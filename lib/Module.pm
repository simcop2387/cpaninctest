package Module;
use 5.22.0;
use Moose;
use Dist;
use Module::CoreList;
use Storable;
use IPC::Run qw/run/;
no warnings 'experimental';

has 'name' => (is => 'ro');
has 'dist' => (is => 'ro',
	builder => '_get_dist',
	lazy => 1);

has 'depends' => (
    builder => 'get_deps',
    is => 'ro',
    isa => 'ArrayRef[Module]',
    lazy => 1,
);

sub _get_dist {
	my $self = shift;
	return $Dist::mod_to_dist{$self->name} // $self->name;
}

our %cache;
if (-e 'modcache.stor') {
    eval {
      my $cache_href=retrieve('modcache.stor');
      %cache = $cache_href->%*;
    };
    if ($@) {
        print STDERR "Couldn't load cache $@\n";
    }
}

sub __save_cache {
 store \%cache, 'modcache.stor';
};
END {__save_cache};

sub new_module {
    my $class = shift;
    my $module = shift;
    my ($name, $version) = split (/[\-~]/, $module);

    my $dist = $Dist::mod_to_dist{$name} // $name;

    return $cache{$dist} if exists $cache{$dist};

    $cache{$dist} = Module->new(name => $name);
}

{
    my @banned = do {open (my $fh, "<banned.lst"); map {chomp; $Dist::mod_to_dist{$_} // $_} <$fh>};
    use Data::Dumper;
    print Dumper(\@banned);
    sub _is_banned {
        my $module = shift;
        my $dist = $Dist::mod_to_dist{$module} // $module;

        return _is_core($module) || ($dist ~~ @banned);
    }
}

sub _is_core {
    my $module = shift;
    my ($name, $version) = split (/[\-~]/, $module);

    my $ret = ($name eq 'perl' || Module::CoreList->first_release($name)) // 0;

    return $ret;
}

sub get_deps {
    my $self=shift;
    my $module = $self->name;

    # skip perl, or core modules
    return [] if _is_banned($module);

    print "Getting deps for $module\n";
    my @cmd = (qw|cpanm --quiet --mirror http://cpan.simcop2387.info/ --showdeps|, $module);

    $SIG{TERM}="ignore";
    my $out;
    run \@cmd, '>&', \$out;

    my $deps = [map {Module->new_module($_)} grep {!_is_core($_)} split($/, $out)];
    __save_cache;
    return $deps;
}

sub print_deps {
    my ($self, $level, $v) = @_;

    for my $dep ($self->depends->@*) {
        my $name = $dep->name;
        print ((" " x $level), $name, "\n");
        $dep->print_deps($level+1, [@$v, $name]) unless ($name ~~ @$v);
    }
}

1;
