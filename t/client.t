#!/usr/bin/env perl

use common::sense;
use utf8;

use Test::More;

BEGIN { use_ok 'CyberSource::SOAP::Lite'; };

=h3 SOAP Sample

<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <Header>
    <Security mustUnderstand="1"
              xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/ oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <UsernameToken Id="uuid-90128b0b-6212-4e16-9382- e55489fa6444-1">
        <Username>merchant ID</Username>
        <Password Type="http://docs.oasis-open.org/wss/2004/01/ oasis-200401-wssusername-token-profile- 1.0#PasswordText">password (セキュ リ テ ィ キー)</Password>
      </UsernameToken>
    </Security>
  </Header>
  <Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <requestMessage xmlns="urn:schemas-cybersource-com: transaction-data-1.28">
      <merchantID>merchant ID</merchantID>
      <merchantReferenceCode>MRC-123456</merchantReferenceCode>
      <billTo>
        <firstName> 桂 </firstName>
        <lastName> 岩佐 </lastName>
        <street1> 渋谷 3 - 1 - 11</street1>
        <city> 渋谷区 </city>
        <state> 東京都 </state>
        <postalCode>150-0002</postalCode>
        <country>JP</country>
        <email>null@cybersource.com</email>
      </billTo>
      <purchaseTotals>
        <currency>JPY</currency>
        <grandTotalAmount>1000</grandTotalAmount>
      </purchaseTotals>
      <card>
        <accountNumber>4111111111111111</accountNumber>
        <expirationMonth>12</expirationMonth>
        <expirationYear>2020</expirationYear>
      </card>
      <ccAuthService run="true"/>
    </requestMessage>
  </Body>
</Envelope>

=cut


#------------------------------------------------------------------------------
#  Before using this example, replace the generic values with your merchant ID and password.

use constant MERCHANT_ID      => '';
use constant TRANSACTION_KEY  => '';

use constant ACCOUNT_NUMBER   => '';
use constant EXPIRATION_YEAR  => 0;
use constant EXPIRATION_MONTH => 0;
use constant CV_NUMBER        => 0; # security code

my $soap = CyberSource::SOAP::Lite->new(
    merchant_id             => MERCHANT_ID,
    transaction_key         => TRANSACTION_KEY,
    merchant_reference_code => 123456,
    cybs_host               => 'ics2wstest.ic3.com',
    logging                 => sub { print @_ }
);

isa_ok $soap, 'CyberSource::SOAP::Lite';

$soap->append_field(billTo => {
    firstName  => '桂',
    lastName   => '岩佐',
    postalCode => '150-0002',
    street1    => '渋谷区渋谷3-1-11',
    street2    => '',
    city       => '',
    state      => '東京都',
    country    => 'jp',
    email      => 'test@example.com',
    ipAddress  => '61.115.125.5'
});

$soap->append_field(shipTo => {
    firstName  => '桂',
    lastName   => '岩佐',
    postalCode => '150-0002',
    street1    => '渋谷区渋谷3-1-11',
    street2    => 'hogehoge',
    city       => '',
    state      => '東京都',
    country    => 'jp',
});

$soap->append_field(card => {
    accountNumber   => ACCOUNT_NUMBER,
    expirationYear  => EXPIRATION_YEAR,
    expirationMonth => EXPIRATION_MONTH,
    cvNumber        => CV_NUMBER,
});

$soap->append_items(map {
    my $q = int(rand 5) + 1;
    {
        productName => sprintf('test%03d', $q),
        quantity    => $q,
        unitPrice   => 525 * $q
    };
} (1 .. 3));

isa_ok $soap->billTo, 'CyberSource::SOAP::Lite::BillTo';
isa_ok $soap->shipTo, 'CyberSource::SOAP::Lite::ShipTo';
isa_ok $soap->card,   'CyberSource::SOAP::Lite::Card';

$soap->checkout(sub {
    my $reply = shift;

    ok !$reply->fault, "faultstring not exists";
    return if $reply->fault;

    ok $reply->match('//Body/replyMessage'), "replyMessage exists";
    return unless $reply->match('//Body/replyMessage');

    like $reply->valueof('//decision'), qr/ACCEPT/, "decition =~ /ACCEPT/";
    return if $reply->valueof('//decision') !~ /ACCEPT/;
});

done_testing;
