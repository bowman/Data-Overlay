use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay overlay_all);
use FindBin;
use lib "$FindBin::Bin/inc";
use Data::Overlay::Test qw(olok dt);

# olok is overlay ok
# dt is dump terse

=for debugging
perl -Ilib -MYAML::XS -MData::Overlay -le 'print "TOP ", Dump ' -e \
    'overlay({a=>2},{a=>{"=default"=>1}})'
=cut

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
