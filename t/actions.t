use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay overlay_all);

=for debugging
perl -Ilib -MYAML::XS -MData::Overlay -le 'print "TOP ", Dump ' -e \
    'overlay({a=>2},{a=>{"=default"=>1}})'
=cut

# =default
cmp_deeply(overlay({a=>2},{a=>{'=default'=>1}}),{a=>2},
                "{a=>2} +++ {a=>{'=default'=>1}} = {a=>2}");
cmp_deeply(overlay({a=>0},{a=>{'=default'=>1}}),{a=>0},
                "{a=>0} +++ {a=>{'=default'=>1}} = {a=>0}");
cmp_deeply(overlay({a=>''},{a=>{'=or'=>1}}),{a=>1},
                "{a=>''} +++ {a=>{'=default'=>1}} = {a=>''}");
cmp_deeply(overlay({a=>undef},{a=>{'=default'=>1}}),{a=>1},
                "{a=>undef} +++ {a=>{'=default'=>1}} = {a=>1}");
cmp_deeply(overlay({a=>{b=>2}},{a=>{'=default'=>1}}),{a=>{b=>2}},
                "{a=>{b=>2}} +++ {a=>{'=default'=>1}} = {a=>{b=>2}}");

# =or
cmp_deeply(overlay({a=>2},{a=>{'=or'=>1}}),{a=>2},
                "{a=>{b=>2}} +++ {a=>{'=or'=>1}} = {a=>{b=>2}}");
cmp_deeply(overlay({a=>0},{a=>{'=or'=>1}}),{a=>1},
                "{a=>0} +++ {a=>{'=or'=>1}} = {a=>1}");
cmp_deeply(overlay({a=>''},{a=>{'=or'=>1}}),{a=>1},
                "{a=>''} +++ {a=>{'=or'=>1}} = {a=>1}");
cmp_deeply(overlay({a=>undef},{a=>{'=or'=>1}}),{a=>1},
                "{a=>undef} +++ {a=>{'=or'=>1}} = {a=>1}");
cmp_deeply(overlay({a=>{b=>2}},{a=>{'=or'=>1}}),{a=>{b=>2}},
                "{a=>{b=>2}} +++ {a=>{'=or'=>1}} = {a=>{b=>2}}");

# =defaults
cmp_deeply(overlay({a=>2},{'=defaults'=>{a=>1}}),{a=>2},
                "{a=>2} +++ {'=defaults' => {a=>1}} = {a=>2}");
cmp_deeply(overlay({a=>0},{'=defaults'=>{a=>1}}),{a=>0},
                "{a=>0} +++ {'=defaults' => {a=>1}} = {a=>0}");
cmp_deeply(overlay({a=>''},{'=defaults'=>{a=>1}}),{a=>''},
                "{a=>''} +++ {'=defaults' => {a=>1}} = {a=>''}");
cmp_deeply(overlay({a=>undef},{'=defaults'=>{a=>1}}),{a=>1},
                "{a=>undef} +++ {'=defaults' => {a=>1}} = {a=>1}");
cmp_deeply(overlay({a=>{b=>2}},{'=defaults'=>{a=>1}}),{a=>{b=>2}},
                "{a=>{b=>2}} +++ {'=defaults' => {a=>1}} = {a=>{b=>2}}");
cmp_deeply(overlay({a=>{b=>2}},{'=defaults'=>{c=>1}}),{a=>{b=>2},c=>1},
                "{a=>{b=>2}} +++ {'=defaults' => {c=>1}} = {a=>{b=>2},c=>1}");

# =push =pop =shift =unshift
cmp_deeply(overlay({a=>[2]},{a=>{'=push'=>1}}),{a=>[2,1]},
                "{a=>[2]} ++ {a=>{'=push'=>1}} = {a=>[2,1]}");
cmp_deeply(overlay({a=>[3,2]},{a=>{'=push'=>1}}),{a=>[3,2,1]},
                "{a=>[3,2]} ++ {a=>{'=push'=>1}} = {a=>[3,2,1]}");
cmp_deeply(overlay({a=>[]},{a=>{'=push'=>1}}),{a=>[1]},
                "{a=>[]} ++ {a=>{'=push'=>1}} = {a=>[1]}");
cmp_deeply(overlay({a=>0},{a=>{'=push'=>1}}),{a=>[0,1]},
                "{a=>0} ++ {a=>{'=push'=>1}} = {a=>[0,1]}");
cmp_deeply(overlay({a=>''},{a=>{'=push'=>1}}),{a=>['',1]},
                "{a=>''} ++ {a=>{'=push'=>1}} = {a=>['',1]}");
cmp_deeply(overlay({a=>undef},{a=>{'=push'=>1}}),{a=>[undef,1]},
                "{a=>undef} ++ {a=>{'=push'=>1}} = {a=>[undef,1]}");

cmp_deeply(overlay({a=>[2]},{a=>{'=push'=>1}}),{a=>[2,1]},
                "{a=>[2]} ++ {a=>{'=push'=>1}} = {a=>[2,1]}");
cmp_deeply(overlay({a=>[3,2]},{a=>{'=push'=>1}}),{a=>[3,2,1]},
                "{a=>[3,2]} ++ {a=>{'=push'=>1}} = {a=>[3,2,1]}");
cmp_deeply(overlay({a=>[]},{a=>{'=push'=>1}}),{a=>[1]},
                "{a=>[]} ++ {a=>{'=push'=>1}} = {a=>[1]}");
cmp_deeply(overlay({a=>0},{a=>{'=push'=>1}}),{a=>[0,1]},
                "{a=>0} ++ {a=>{'=push'=>1}} = {a=>[0,1]}");
cmp_deeply(overlay({a=>''},{a=>{'=push'=>1}}),{a=>['',1]},
                "{a=>''} ++ {a=>{'=push'=>1}} = {a=>['',1]}");
cmp_deeply(overlay({a=>undef},{a=>{'=default'=>[],'=push'=>1}}),{a=>[1]},
                "{a=>undef} ++ {a=>{'=default'=>[],'=push'=>1}} = {a=>[1]}");

# scalar/non-ARRAY upgrade
cmp_deeply(overlay({a=>2},{a=>{'=push'=>1}}),{a=>[2,1]},
                "{a=>2} ++ {a=>{'=push'=>1}} = {a=>[2,1]}");
cmp_deeply(overlay({a=>{b=>2}},{a=>{'=push'=>1}}),{a=>[{b=>2},1]},
                "{a=>{b=>2}} +++ {a=>{'=push'=>1}} = {a=>[{b=>2}},1]");
# =code
# =config

done_testing();
