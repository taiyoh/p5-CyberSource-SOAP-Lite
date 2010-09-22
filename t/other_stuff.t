use common::sense;
use utf8;

use Test::More;

BEGIN { use_ok 'CyberSource::SOAP::Lite'; };

do {
    package CYBS_TestBillTo;
    use Any::Moose;
    extends 'CyberSource::SOAP::Lite::BillTo';

    has [qw/firstCanna lastCanna/] => (
        is      => 'rw',
        isa     => 'Str',
        default => ''
    );

    around make => sub {
        my $orig = shift;
        my $self = shift;
        my $val = $orig->($self);
        for (qw/firstCanna lastCanna/) {
            push @$val, SOAP::Data->name($_ => $self->$_);
        }
        return $val;
    };
};

my $soap = CyberSource::SOAP::Lite->new(
    merchant_id             => 'aaaaaaaaa',
    transaction_key         => 'bbbbbbbbbbbbbbbbbbbbb',
    merchant_reference_code => 123456,
    cybs_host               => 'ics2wstest.ic3.com',
    logging                 => sub { print @_ }
);

isa_ok $soap, 'CyberSource::SOAP::Lite';

$soap->append_field('+CYBS_TestBillTo' => {
    firstName  => '桂',
    lastName   => '岩佐',
    firstCanna  => 'ケイ',
    lastCanna   => 'イワサ',
    postalCode => '150-0002',
    street1    => '渋谷区渋谷3-1-11',
    street2    => '',
    city       => '',
    state      => '東京都',
    country    => 'jp',
    email      => 'test@example.com',
    ipAddress  => '61.115.125.5'
});

ok $soap->billTo, 'billTo exists';
isa_ok $soap->billTo, 'CYBS_TestBillTo', 'isa CYBS_TestBillTo';

done_testing;
