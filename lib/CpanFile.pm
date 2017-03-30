package cpanfile;
# HACK since cpan files are valid perl, i'm just using do/require
use 5.22.0;

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
