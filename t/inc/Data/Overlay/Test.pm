package Data::Overlay::Test;

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay);
use Exporter 'import';
our @EXPORT = qw(olok dt);

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

sub dt {
    my $dumper = Data::Dumper->new( map [$_], @_ );
    $dumper->Indent(0)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}

1;
