use inc::Module::Install;
name 'CyberSource-SOAP-Lite';
all_from 'lib/CyberSource/SOAP/Lite.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
