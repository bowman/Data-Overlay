package # hide from CPAN
    Data::Overlay::Test;

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay);
use Exporter 'import';
our @EXPORT = qw(olok dt);

# name internal _dt as dt for use in testing (not part of the API)
*dt = \&Data::Overlay::_dt;

sub olok {
    my ($ds, $overlay, $expect) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    cmp_deeply( overlay( $ds,  $overlay) =>  $expect,
                     dt( $ds ).' ~ '.dt($overlay).' ~> '.dt($expect) )
        or diag "ds  = ", explain($ds),
                "ol  = ", explain($overlay),
                "exp = ", explain($expect),
                "got = ", explain(overlay( $ds,  $overlay)),
}

1;
