use inc::Module::Install;
name 'CyberSource-SOAP-Lite';
all_from 'lib/CyberSource/SOAP/Lite.pm';

requires 'Any::Moose';
requires 'Mouse';
requires 'SOAP::Lite';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
