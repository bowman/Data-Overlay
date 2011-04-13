use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay overlay_all);

=for debugging
perl -Ilib -MYAML::XS -MData::Overlay -le 'print "TOP ", Dump ' -e \
    'overlay({a=>2},{a=>{"=default"=>1}})'
=cut
sub olok {
    my ($ds, $overlay, $expect) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    cmp_deeply( overlay( $ds,  $overlay) =>  $expect,
                     dt( $ds ).' ~ '.dt($overlay).' ~> '.dt($expect) )
        or diag explain($ds, $overlay, $expect);

}

sub dt {
    my $dumper = Data::Dumper->new( map [$_], @_ );
    $dumper->Indent(0)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}

# =default
olok({a=>2},{a=>{'=default'=>1}} => {a=>2});
olok({a=>0},{a=>{'=default'=>1}} => {a=>0});
olok({a=>''},{a=>{'=or'=>1}} => {a=>1});
olok({a=>undef},{a=>{'=default'=>1}} => {a=>1});
olok({a=>{b=>2}},{a=>{'=default'=>1}} => {a=>{b=>2}});

# =or
olok({a=>2},{a=>{'=or'=>1}} => {a=>2});
olok({a=>0},{a=>{'=or'=>1}} => {a=>1});
olok({a=>''},{a=>{'=or'=>1}} => {a=>1});
olok({a=>undef},{a=>{'=or'=>1}} => {a=>1});
olok({a=>{b=>2}},{a=>{'=or'=>1}} => {a=>{b=>2}});

# =defaults
olok({a=>2},{'=defaults'=>{a=>1}} => {a=>2});
olok({a=>0},{'=defaults'=>{a=>1}} => {a=>0});
olok({a=>''},{'=defaults'=>{a=>1}} => {a=>''});
olok({a=>undef},{'=defaults'=>{a=>1}} => {a=>1});
olok({a=>{b=>2}},{'=defaults'=>{a=>1}} => {a=>{b=>2}});
olok({a=>{b=>2}},{'=defaults'=>{c=>1}} => {a=>{b=>2},c=>1});

# =push =pop =shift =unshift
olok({a=>[1]},{a=>{'=push'=>2}} => {a=>[1,2]});
olok({a=>[1,2]},{a=>{'=push'=>3}} => {a=>[1,2,3]});
olok({a=>[]},{a=>{'=push'=>1}} => {a=>[1]});
olok({a=>0},{a=>{'=push'=>1}} => {a=>[0,1]});
olok({a=>''},{a=>{'=push'=>1}} => {a=>['',1]});
olok({a=>undef}, {a=>{'=push'=>1}} => {a=>[undef,1]});

olok({a=>[2]},{a=>{'=push'=>1}} => {a=>[2,1]});
olok({a=>[3,2]},{a=>{'=push'=>1}} => {a=>[3,2,1]});
olok({a=>[]},{a=>{'=push'=>1}} => {a=>[1]});
olok({a=>0},{a=>{'=push'=>1}} => {a=>[0,1]});
olok({a=>''},{a=>{'=push'=>1}} => {a=>['',1]});
olok({a=>undef},{a=>{'=default'=>[],'=push'=>1}} => {a=>[1]});

# scalar/non-ARRAY upgrade
olok({a=>2},{a=>{'=push'=>1}} => {a=>[2,1]});
olok({a=>{b=>2}},{a=>{'=push'=>1}} => {a=>[{b=>2},1]});


# =code
# =config

done_testing();
