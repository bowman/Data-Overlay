use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay overlay_all);

### overlay checks

# no change with empty overlay
cmp_deeply(overlay({},undef),undef, "{} +++ undef = undef"); #???
cmp_deeply(overlay({},{}),{}, "{} +++ {} = {}");
cmp_deeply(overlay(undef,{}),{}, "undef +++ {} = {}");
cmp_deeply(overlay({a=>1},{}),{a=>1}, "{a=>1} +++ {} = {a=>1}");
cmp_deeply(overlay({},{a=>1}),{a=>1}, "{} +++ {a=>1} = {a=>1}");
cmp_deeply(overlay({},{a=>1},{a=>1}),{a=>1}, "{} +++ {a=>1} = {a=>1}");
cmp_deeply(overlay({a=>{b=>2}},{}),{a=>{b=>2}},
                  "{a=>{b=>2}} +++ {} = {a=>{b=>2}}");
cmp_deeply(overlay({},{a=>{b=>2}}),{a=>{b=>2}},
                  "{} +++ {a=>{b=>2}} = {a=>{b=>2}}");

# overlay_all
cmp_deeply(overlay_all({},{},{}),{}, "{} +++ {} +++ {} = {}");
cmp_deeply(overlay_all({},{a=>1},{a=>1}),{a=>1}, "{} +++ {a=>1}x2 = {a=>1}");
cmp_deeply(overlay_all({},{a=>1},{a=>2}),{a=>2}, "{} +++ {a=>1} +++ {a=>2} = {a=>2}");
cmp_deeply(overlay_all({},{a=>1},{a=>{b=>2}}),{a=>{b=>2}},
                  "{} +++ {a=>1} +++ {a=>{b=>2}} = {a=>{b=>2}}");

# hash changes
cmp_deeply(overlay({a=>1},{a=>2}),{a=>1,a=>2}, "{a=>1} +++ {a=>2} = {a=>1,a=>2}");
cmp_deeply(overlay({a=>1},{b=>2}),{a=>1,b=>2}, "{a=>1} +++ {b=>2} = {a=>1,b=>2}");

# overlay overwrites (diff types)
cmp_deeply(overlay({a=>{b=>2}},{a=>1}),{a=>1}, "{a=>{b=>2}} +++ {a=>1} = {a=>1}");
cmp_deeply(overlay({a=>1},{a=>{b=>2}}),{a=>{b=>2}}, "{a=>1} +++ {a=>{b=>2}} = {a=>1}");

# lower level
cmp_deeply(overlay({a=>{c=>[123]}},{a=>{b=>2}}),{a=>{b=>2,c=>[123]}},
            "{a=>{c=>[123]}} +++ {a=>{b=>2}} = {a=>{b=>2,c=>[123]}}");
cmp_deeply(overlay({a=>{c=>[123]}},{a=>{b=>{d=>2}}}),{a=>{b=>{d=>2},c=>[123]}},
            "{a=>{c=>[123]}} +++ {a=>{b=>{d=>2}}} = {a=>{b=>{d=>2}},c=>[123]}}");
# should be the same [123]

# TODO check memory match (empty overlay?)

### compose checks
#cmp_deeply(compose({},{}),{},"{} <+> {} = {}");

done_testing();
