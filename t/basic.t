use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Tweak qw(tweak);

### tweak checks

# no change with empty tweak
cmp_deeply(tweak({}),{}, "{} +++ () = {}");
#cmp_deeply(tweak({},undef),{}, "{} +++ undef = {}"); #???
cmp_deeply(tweak({},{}),{}, "{} +++ {} = {}");
cmp_deeply(tweak(undef,{}),{}, "undef +++ {} = {}");
cmp_deeply(tweak({a=>1},{}),{a=>1}, "{a=>1} +++ {} = {a=>1}");
cmp_deeply(tweak({},{a=>1}),{a=>1}, "{} +++ {a=>1} = {a=>1}");
cmp_deeply(tweak({a=>{b=>2}},{}),{a=>{b=>2}}, "{a=>{b=>2}} +++ {} = {a=>{b=>2}}");
cmp_deeply(tweak({},{a=>{b=>2}}),{a=>{b=>2}}, "{} +++ {a=>{b=>2}} = {a=>{b=>2}}");

# hash changes
cmp_deeply(tweak({a=>1},{a=>2}),{a=>1,a=>2}, "{a=>1} +++ {a=>2} = {a=>1,a=>2}");
cmp_deeply(tweak({a=>1},{b=>2}),{a=>1,b=>2}, "{a=>1} +++ {b=>2} = {a=>1,b=>2}");

# tweak overwrites (diff types)
cmp_deeply(tweak({a=>{b=>2}},{a=>1}),{a=>1}, "{a=>{b=>2}} +++ {a=>1} = {a=>1}");
cmp_deeply(tweak({a=>1},{a=>{b=>2}}),{a=>{b=>2}}, "{a=>1} +++ {a=>{b=>2}} = {a=>1}");

# lower level
cmp_deeply(tweak({a=>{c=>[123]}},{a=>{b=>2}}),{a=>{b=>2,c=>[123]}},
            "{a=>{c=>[123]}} +++ {a=>{b=>2}} = {a=>{b=>2,c=>[123]}}");
cmp_deeply(tweak({a=>{c=>[123]}},{a=>{b=>{d=>2}}}),{a=>{b=>{d=>2},c=>[123]}},
            "{a=>{c=>[123]}} +++ {a=>{b=>{d=>2}}} = {a=>{b=>{d=>2}},c=>[123]}}");
# should be the same [123]

# TODO check memory match (empty tweak?)
# =default
cmp_deeply(tweak({a=>2},{a=>{'=default'=>1}}),{a=>2},
                "{a=>2} +++ {a=>{'=default'=>1}} = {a=>2}");
cmp_deeply(tweak({a=>0},{a=>{'=default'=>1}}),{a=>0},
                "{a=>0} +++ {a=>{'=default'=>1}} = {a=>0}");
cmp_deeply(tweak({a=>''},{a=>{'=or'=>1}}),{a=>1},
                "{a=>''} +++ {a=>{'=default'=>1}} = {a=>''}");
cmp_deeply(tweak({a=>undef},{a=>{'=default'=>1}}),{a=>1},
                "{a=>undef} +++ {a=>{'=default'=>1}} = {a=>1}");
cmp_deeply(tweak({a=>{b=>2}},{a=>{'=default'=>1}}),{a=>{b=>2}},
                "{a=>{b=>2}} +++ {a=>{'=default'=>1}} = {a=>{b=>2}}");

# =or
cmp_deeply(tweak({a=>2},{a=>{'=or'=>1}}),{a=>2},
                "{a=>{b=>2}} +++ {a=>{'=or'=>1}} = {a=>{b=>2}}");
cmp_deeply(tweak({a=>0},{a=>{'=or'=>1}}),{a=>1},
                "{a=>0} +++ {a=>{'=or'=>1}} = {a=>1}");
cmp_deeply(tweak({a=>''},{a=>{'=or'=>1}}),{a=>1},
                "{a=>''} +++ {a=>{'=or'=>1}} = {a=>1}");
cmp_deeply(tweak({a=>undef},{a=>{'=or'=>1}}),{a=>1},
                "{a=>undef} +++ {a=>{'=or'=>1}} = {a=>1}");
cmp_deeply(tweak({a=>{b=>2}},{a=>{'=or'=>1}}),{a=>{b=>2}},
                "{a=>{b=>2}} +++ {a=>{'=or'=>1}} = {a=>{b=>2}}");
# =push =pop =shift =unshift
# =code

### compose checks
#cmp_deeply(compose({},{}),{},"{} <+> {} = {}");

done_testing();
