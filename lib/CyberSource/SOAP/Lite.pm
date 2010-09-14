package CyberSource::SOAP::Lite;

use Any::Moose;
use utf8;

use SOAP::Lite;

our $VERSION = '0.01';

has logging         => ( is => 'rw', isa => 'CodeRef' );

has merchant_id     => ( is => 'ro', isa => 'Str', required => 1 );
has transaction_key => ( is => 'ro', isa => 'Str', required => 1 );
has wsse_prefix     => ( is => 'ro', isa => 'Str', required => 1, default => sub { 'wsse' } );
has cybs_host       => ( is => 'ro', isa => 'Str', required => 1, default => sub { 'ics2ws.ic3.com' } );
has merchant_reference_code => ( is => 'ro', isa => 'Str', required => 1 );

has wsse_nsuri => (
    is => 'ro', isa => 'Str', required => 1,
    default => sub {
        'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'
    }
);

has password_text => (
    is => 'ro', isa => 'Str', required => 1,
    default => sub {
        'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText'
    }
);

has proxy => (
    is => 'ro', isa  => 'Str', lazy => 1,
    default => sub {
        my $self = shift;
        sprintf('https://%s/commerce/1.x/transactionProcessor', $self->cybs_host);
    }
);

has uri => (
    is => 'ro', isa => 'Str', lazy => 1,
    default => sub { 'urn:schemas-cybersource-com:transaction-data-1.26'; }
);

has header => (
    is => 'ro',
    isa => 'SOAP::Header',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $usernameToken = SOAP::Data->name(
            UsernameToken => {
                Username => SOAP::Data -> type('', $self->merchant_id)
                                       -> prefix($self->wsse_prefix),
                Password => SOAP::Data -> type('', $self->transaction_key)
                                       -> attr({ Type => $self->password_text })
                                       -> prefix($self->wsse_prefix)
            }
        )->prefix($self->wsse_prefix);

        SOAP::Header->name(
            Security => {
                UsernameToken =>
                    SOAP::Data->type('', $usernameToken)
            }
        )->uri($self->wsse_nsuri)
         ->prefix($self->wsse_prefix);
    }
);

has service => (
    is      => 'ro',
    isa     => 'SOAP::Lite',
    lazy    => 1,
    default => sub {
        my $self = shift;
        if ($self->logging && ref $self->logging eq 'CODE') {
            SOAP::Lite->import(+trace => debug => $self->logging);
        }
        return SOAP::Lite
            ->proxy($self->proxy)
            ->uri($self->uri)
            ->autotype(0);
    }
);

has request => (
    is      => 'rw',
    isa     => 'ArrayRef',
);

for my $p (qw/billTo shipTo purchaseTotals card/) {
    has $p => ( is => 'rw', isa => 'CyberSource::SOAP::Lite::'.ucfirst($p) );
}

has items => (
    is   => 'rw',
    isa  => 'ArrayRef[CyberSource::SOAP::Lite::Item]',
    lazy => 1,
    default => sub { [] }
);

has response => ( is => 'rw', isa => 'Any', );

no Any::Moose;

sub add_item($) {
    my ($self, $item) = @_;
    my $items = $self->items;
    push @$items, $item;
    $self->items($items);
}

sub make_request {
    my $self = shift;

    $self->add_field( merchantID => $self->merchant_id );
    $self->add_field( merchantReferenceCode => $self->merchant_reference_code );
    $self->add_field( clientLibrary => 'Perl' );
    $self->add_field( clientLibraryVersion => "$]" );
    $self->add_field( clientEnvironment => "$^O" );

    # billTo
    $self->add_field( $self->billTo->make ) if $self->billTo;
    # shipTo
    $self->add_field( $self->shipTo->make ) if $self->shipTo;

    # item
    $self->add_field( $_->make ) for @{ $self->items };
    # purchaseTotals
    $self->add_field($self->purchaseTotals->make) if $self->purchaseTotals;
    # card
    $self->add_field($self->card->make) if $self->card;
    # ccAuthService
    $self->add_field( ccAuthService => [], { run => 'true' } );

    return $self;
}

sub checkout {
    my $self = shift;
    my $callback = shift || sub {};
    $self->make_request unless $self->request;
    my $request = $self->request;

    return unless @$request;

    my $reply = $self->service->call(
        'requestMessage',
        @$request,
        $self->header
    );
    $self->response($reply);

    $callback->($reply);

    return $self;
}

sub add_field {
    my $self = shift;
    my ($key, $val, $attr) = @_;
    my $n;
    if (ref($val) eq 'ARRAY') {
        $n = SOAP::Data->name($key, \SOAP::Data->value(@$val));
    }
    else {
        $n = SOAP::Data->name($key, $val);
    }
    $n = $n->attr($attr) if $attr;
    my $reqs = $self->request;
    push @$reqs, $n;
    $self->request($reqs);
}

sub append_field($$) {
    my $self = shift;
    my ($key, $data) = @_;
    my $cls = ucfirst($key);
    my $klass = "CyberSource::SOAP::Lite::${cls}";
    Any::Moose::load_class($klass)
          unless Any::Moose::is_class_loaded($klass);
    $self->$key($klass->new($data));
}

sub append_items(@) {
    my $self = shift;
    my $klass = "CyberSource::SOAP::Lite::Item";
    Any::Moose::load_class($klass)
          unless Any::Moose::is_class_loaded($klass);
    $self->add_item($klass->new($_)) for @_;
}

__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

CyberSource::SOAP::Lite -

=head1 SYNOPSIS

  use CyberSource::SOAP::Lite;

=head1 DESCRIPTION

CyberSource::SOAP::Lite is

=head1 AUTHOR

Taiyoh Tanaka E<lt>sun.basix@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
