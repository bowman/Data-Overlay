use strict;
use warnings;

use Test::More;
use Data::Tweak qw(tweak);

### tweak checks

# no change with empty tweak
is_deeply(tweak({}),{}, "{} +++ () = {}");
#is_deeply(tweak({},undef),{}, "{} +++ undef = {}"); #???
is_deeply(tweak({},{}),{}, "{} +++ {} = {}");
is_deeply(tweak(undef,{}),{}, "undef +++ {} = {}");
is_deeply(tweak({a=>1},{}),{a=>1}, "{a=>1} +++ {} = {a=>1}");
is_deeply(tweak({},{a=>1}),{a=>1}, "{} +++ {a=>1} = {a=>1}");
is_deeply(tweak({a=>{b=>2}},{}),{a=>{b=>2}}, "{a=>{b=>2}} +++ {} = {a=>{b=>2}}");
is_deeply(tweak({},{a=>{b=>2}}),{a=>{b=>2}}, "{} +++ {a=>{b=>2}} = {a=>{b=>2}}");

# hash changes
is_deeply(tweak({a=>1},{a=>2}),{a=>1,a=>2}, "{a=>1} +++ {a=>2} = {a=>1,a=>2}");
is_deeply(tweak({a=>1},{b=>2}),{a=>1,b=>2}, "{a=>1} +++ {b=>2} = {a=>1,b=>2}");

# tweak overwrites (diff types)
is_deeply(tweak({a=>{b=>2}},{a=>1}),{a=>1}, "{a=>{b=>2}} +++ {a=>1} = {a=>1}");
is_deeply(tweak({a=>1},{a=>{b=>2}}),{a=>{b=>2}}, "{a=>1} +++ {a=>{b=>2}} = {a=>1}");

# lower level
is_deeply(tweak({a=>{c=>[123]}},{a=>{b=>2}}),{a=>{b=>2,c=>[123]}},
            "{a=>{c=>[123]}} +++ {a=>{b=>2}} = {a=>{b=>2,c=>[123]}}");
is_deeply(tweak({a=>{c=>[123]}},{a=>{b=>{d=>2}}}),{a=>{b=>{d=>2},c=>[123]}},
            "{a=>{c=>[123]}} +++ {a=>{b=>{d=>2}}} = {a=>{b=>{d=>2}},c=>[123]}}");
# should be the same [123]

# TODO check memory match (empty tweak?)
# =default =or
# =push =pop =shift =unshift
# =code

### compose checks
#is_deeply(compose({},{}),{},"{} <+> {} = {}");

done_testing();
