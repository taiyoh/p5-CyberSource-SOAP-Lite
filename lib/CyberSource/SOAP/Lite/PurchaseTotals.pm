package CyberSource::SOAP::Lite::PurchaseTotals;

use Any::Moose;
with 'CyberSource::SOAP::Lite::RequestRole';

my @keys = qw/currency/;

has '+keys' => ( default => sub { [@keys]} );
has '+node' => ( default => sub { 'purchaseTotals' } );

has currency  => ( is => 'rw', isa => 'Str' );

no Any::Moose;

__PACKAGE__->meta->make_immutable;
