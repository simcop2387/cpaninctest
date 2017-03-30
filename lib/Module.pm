package Module;
use 5.22.0;
use Moose;
use Dist;
use Module::CoreList;
use Storable;
use IPC::Run qw/run/;
no warnings 'experimental';

has 'name' => (is => 'ro');

has 'depends' => (
    builder => 'get_deps',
    is => 'ro',
    isa => 'ArrayRef[Module]',
    lazy => 1,
);

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

END {
 store \%cache, 'modcache.stor';
};

sub new_module {
    my $class = shift;
    my $module = shift;
    my ($name, $version) = split (/[\-~]/, $module);

    my $dist = $Dist::mod_to_dist{$name} // $name;

    return $cache{$dist} if exists $cache{$dist};

    $cache{$dist} = Module->new(name => $name);
}

sub _is_core {
    my $module = shift;
    my ($name, $version) = split (/[\-~]/, $module);

    my $ret = ($name eq 'perl' || Module::CoreList->first_release($name)) // 0;

    return $ret;
}

sub get_dist {
    my $self=shift;
    my $module = $self->name;

    # skip perl, or core modules
    return 'perl' if _is_core($module);

    my @cmd = (qw|cpanm --quiet --mirror http://cpan.simcop2387.info/ --info|, $module);
    my $out;
    run \@cmd, '>&', \$out;

    chomp $out;
    return $out;
}

sub get_deps {
    my $self=shift;
    my $module = $self->name;

    # skip perl, or core modules
    return [] if _is_core($module);

    my @cmd = (qw|cpanm --quiet --mirror http://cpan.simcop2387.info/ --showdeps|, $module);

    my $out;
    run \@cmd, '>&', \$out;

    return [map {Module->new_module($_)} grep {!_is_core($_)} split($/, $out)];
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

1;