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

# =push
olok({a=>[1]},{a=>{'=push'=>2}} => {a=>[1,2]});
olok({a=>[1,2]},{a=>{'=push'=>3}} => {a=>[1,2,3]});
olok({a=>[]},{a=>{'=push'=>1}} => {a=>[1]});
# scalar/non-ARRAY upgrade
olok({a=>1},{a=>{'=push'=>2}} => {a=>[1,2]});
olok({a=>{b=>2}},{a=>{'=push'=>1}} => {a=>[{b=>2},1]});
olok({a=>0},{a=>{'=push'=>1}} => {a=>[0,1]});
olok({a=>''},{a=>{'=push'=>1}} => {a=>['',1]});
olok({a=>undef}, {a=>{'=push'=>1}} => {a=>[undef,1]});
# multi-item pushes
olok({a=>[1]},{a=>{'=push'=>[2,3]}} => {a=>[1,2,3]});
olok({a=>[1]},{a=>{'=push'=>[[2,3]]}} => {a=>[1,[2,3]]});
olok({a=>[1]},{a=>{'=push'=>[[2],[3]]}} => {a=>[1,[2],[3]]});

# =push + =default & =or
olok({a=>[]},{a=>{'=or'=>[],'=push'=>1}} => {a=>[1]});
olok({a=>0},{a=>{'=or'=>[],'=push'=>1}} => {a=>[1]});
olok({a=>''},{a=>{'=or'=>[],'=push'=>1}} => {a=>[1]});
olok({a=>undef},{a=>{'=default'=>[],'=push'=>1}} => {a=>[1]});

# =pop (value doesn't matter)
olok({a=>[1,2]},{a=>{'=pop'=>''}} => {a=>[1]});
olok({a=>[1,2,3]},{a=>{'=pop'=>''}} => {a=>[1,2]});
olok({a=>[1]},{a=>{'=pop'=>'a'}} => {a=>[]});
olok({a=>[0,1]},{a=>{'=pop'=>1}} => {a=>[0]}); # no auto-downgrade
olok({a=>['',1]},{a=>{'=pop'=>1}} => {a=>['']});
olok({a=>[1,'']},{a=>{'=pop'=>1}} => {a=>[1]});
olok({a=>[undef,1]},{a=>{'=pop'=>1}} => {a=>[undef]});
olok({a=>[1,undef]},{a=>{'=pop'=>1}} => {a=>[1]});
# multi-item pops
olok({a=>[1,2,3]},{a=>{'=pop'=>[2,'*']}} => {a=>[1]});
olok({a=>[1,[2,3]]},{a=>{'=pop'=>['*']}} => {a=>[1]});
olok({a=>[1,[2],[3]]},{a=>{'=pop'=>[[2],'*']}} => {a=>[1]});
# pop too far silently leaves []
olok({a=>[1]},{a=>{'=pop'=>[2,'*']}} => {a=>[]});

# =unshift
olok({a=>[1]},{a=>{'=unshift'=>2}} => {a=>[2,1]});
olok({a=>[1,2]},{a=>{'=unshift'=>3}} => {a=>[3,1,2]});
olok({a=>[]},{a=>{'=unshift'=>1}} => {a=>[1]});
# scalar/non-ARRAY upgrade
olok({a=>1},{a=>{'=unshift'=>2}} => {a=>[2,1]});
olok({a=>{b=>2}},{a=>{'=unshift'=>1}} => {a=>[1,{b=>2}]});
olok({a=>0},{a=>{'=unshift'=>1}} => {a=>[1,0]});
olok({a=>''},{a=>{'=unshift'=>1}} => {a=>[1,'']});
olok({a=>undef}, {a=>{'=unshift'=>1}} => {a=>[1,undef]});
# multi-item unshiftes
olok({a=>[1]},{a=>{'=unshift'=>[2,3]}} => {a=>[2,3,1]});
olok({a=>[1]},{a=>{'=unshift'=>[[2,3]]}} => {a=>[[2,3],1]});
olok({a=>[1]},{a=>{'=unshift'=>[[2],[3]]}} => {a=>[[2],[3],1]});

# =unshift + =default & =or
olok({a=>[]},{a=>{'=or'=>[],'=unshift'=>1}} => {a=>[1]});
olok({a=>0},{a=>{'=or'=>[],'=unshift'=>1}} => {a=>[1]});
olok({a=>''},{a=>{'=or'=>[],'=unshift'=>1}} => {a=>[1]});
olok({a=>undef},{a=>{'=default'=>[],'=unshift'=>1}} => {a=>[1]});

# =shift (value doesn't matter)
olok({a=>[1,2]},{a=>{'=shift'=>''}} => {a=>[2]});
olok({a=>[1,2,3]},{a=>{'=shift'=>''}} => {a=>[2,3]});
olok({a=>[1]},{a=>{'=shift'=>'a'}} => {a=>[]});
olok({a=>[0,1]},{a=>{'=shift'=>1}} => {a=>[1]}); # no auto-downgrade
olok({a=>['',1]},{a=>{'=shift'=>1}} => {a=>[1]});
olok({a=>[1,'']},{a=>{'=shift'=>1}} => {a=>['']});
olok({a=>[undef,1]},{a=>{'=shift'=>1}} => {a=>[1]});
olok({a=>[1,undef]},{a=>{'=shift'=>1}} => {a=>[undef]});
# multi-item shifts
olok({a=>[1,2,3]},{a=>{'=shift'=>[2,'*']}} => {a=>[3]});
olok({a=>[1,[2,3]]},{a=>{'=shift'=>['*']}} => {a=>[[2,3]]});
olok({a=>[[1,2],3]},{a=>{'=shift'=>['*']}} => {a=>[3]});
olok({a=>[1,[2],[3]]},{a=>{'=shift'=>[[2],'*']}} => {a=>[[3]]});
olok({a=>[[1],[2],3]},{a=>{'=shift'=>[[2],'*']}} => {a=>[3]});
# shift too far silently leaves []
olok({a=>[1]},{a=>{'=shift'=>[2,'*']}} => {a=>[]});
olok({a=>[1,2]},{a=>{'=shift'=>[1,2,3]}} => {a=>[]});



# =code
# =config

done_testing();
