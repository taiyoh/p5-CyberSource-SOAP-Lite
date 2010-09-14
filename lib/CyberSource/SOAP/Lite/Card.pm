package CyberSource::SOAP::Lite::Card;

use Any::Moose;
with 'CyberSource::SOAP::Lite::RequestRole';

my @keys = qw/
    accountNumber
    expirationMonth expirationYear
/;

has '+keys' => ( default => sub { [@keys]} );
has '+node' => ( default => sub { 'card' } );

has cardType        => ( is => 'rw', isa => 'Str' );
has accountNumber   => ( is => 'rw', isa => 'Str' );
has expirationMonth => ( is => 'rw', isa => 'Int' );
has expirationYear  => ( is => 'rw', isa => 'Int' );

has cvNumber        => ( is => 'rw', isa => 'Any' );
has issueNumber     => ( is => 'rw', isa => 'Any' );
has startMonth      => ( is => 'rw', isa => 'Any' );
has startYear       => ( is => 'rw', isa => 'Any' );

no Any::Moose;

__PACKAGE__->meta->make_immutable;
