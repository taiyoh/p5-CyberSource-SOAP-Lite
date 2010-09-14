package CyberSource::SOAP::Lite::Item;

use Any::Moose;
with 'CyberSource::SOAP::Lite::RequestRole';

my $counter = 0;
my @keys = qw/unitPrice quantity productName/;

has '+keys' => ( default => sub { [@keys] } );
has '+node' => ( default => sub { 'item' } );

has item_id   => (
    is => 'rw', isa => 'Str', lazy => 1,
    default => sub { $counter++ }
);
has productName => ( is => 'rw', isa => 'Str' );
has unitPrice => ( is => 'rw', isa => 'Str' );
has quantity  => ( is => 'rw', isa => 'Int', default => 1 );

no Any::Moose;

sub make {
    my $self  = shift;
    my @value = map { SOAP::Data->name($_ => $self->$_) } @keys;
    return ( item => \@value, { ' id' => $self->item_id } );
}

__PACKAGE__->meta->make_immutable;
