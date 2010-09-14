package CyberSource::SOAP::Lite::BillTo;

use Any::Moose;
with 'CyberSource::SOAP::Lite::RequestRole';

my @keys = qw/
    firstName lastName
    street1 street2 city
    state postalCode country
    email ipAddress
/;
# city
# phoneNumber

has '+keys' => ( default => sub { [@keys]} );
has '+node' => ( default => sub { 'billTo' } );

has( $_ => ( is => 'rw', isa => 'Str', default => sub { '' } ) ) for @keys;

no Any::Moose;

__PACKAGE__->meta->make_immutable;
