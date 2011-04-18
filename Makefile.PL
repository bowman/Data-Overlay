use inc::Module::Install;

name     'Data-Overlay';
all_from 'lib/Data/Overlay.pm';
author   q{Brad Bowman <cpan@bereft.net>};
license  'perl';

requires 'List::MoreUtils';
requires 'Sub::Name';

build_requires 'Test::More';
build_requires 'Test::Deep';

auto_install;

WriteAll;

