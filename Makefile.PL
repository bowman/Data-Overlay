use inc::Module::Install;

name     'Data-Tweak';
all_from 'lib/Data/Tweak.pm';
author   q{Brad Bowman <cpan@bereft.net>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

