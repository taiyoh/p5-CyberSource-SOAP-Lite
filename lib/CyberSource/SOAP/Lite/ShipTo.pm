package CyberSource::SOAP::Lite::ShipTo;

use Any::Moose;
with 'CyberSource::SOAP::Lite::RequestRole';

my @keys = qw/
    firstName lastName
    street1 street2 city
    state postalCode country
/;

has '+keys' => ( default => sub { [@keys]} );
has '+node' => ( default => sub { 'shipTo' } );

has( $_ => ( is => 'rw', isa => 'Str' ) ) for @keys;

no Any::Moose;

__PACKAGE__->meta->make_immutable;
