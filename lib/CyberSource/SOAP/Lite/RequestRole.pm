package CyberSource::SOAP::Lite::RequestRole;

use Any::Moose '::Role';
use SOAP::Lite;

has keys => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
    default    => sub { [] }
);

has node => ( is => 'rw', isa => 'Str' );

no Any::Moose;

sub make {
    my $self = shift;
    my @items = map { SOAP::Data->name($_ => $self->$_) } $self->keys;
    return \@items;
}

1;
