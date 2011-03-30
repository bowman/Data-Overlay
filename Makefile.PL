use inc::Module::Install;

name     'Data-Overlay';
all_from 'lib/Data/Overlay.pm';
author   q{Brad Bowman <cpan@bereft.net>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

