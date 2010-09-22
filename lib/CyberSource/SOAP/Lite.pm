package CyberSource::SOAP::Lite;

use Any::Moose;
use utf8;

use SOAP::Lite;

our $VERSION = '0.02.2';

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
    isa  => 'ArrayRef',
    lazy => 1,
    default => sub { [] }
);

has response => ( is => 'rw', isa => 'Any', );

has clientLibrary        => ( is => 'rw', isa  => 'Str', default => 'Perl' );
has clientLibraryVersion => ( is => 'rw', isa  => 'Str', default => "$]" );
has clientEnvironment    => ( is => 'rw', isa  => 'Str', default => "$^O" );

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

    $self->add_field( $_ => $self->$_ )
        for (qw/clientLibrary clientLibraryVersion clientEnvironment/);

    # billTo
    $self->extract_and_add( $self->billTo );
    # shipTo
    $self->extract_and_add( $self->shipTo );

    # item
    $self->extract_and_add( $_ ) for @{ $self->items };
    # purchaseTotals
    $self->extract_and_add( $self->purchaseTotals );
    # card
    $self->extract_and_add( $self->card );

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

sub extract_and_add {
    my $self  = shift;
    my $field = shift or return;
    my $key = $field->node;
    $self->add_field( $key, $field->make );
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
    my ($klass, $data) = @_;
    unless ($klass =~ s{^\+}{}) {
        $klass = 'CyberSource::SOAP::Lite::' . ucfirst($klass);
    }
    Any::Moose::load_class($klass)
          unless Any::Moose::is_class_loaded($klass);
    my $module = $klass->new($data);
    my $key = $module->node;
    $self->$key($module);
}

sub append_items {
    my $self = shift;
    my $klass = !ref($_[0]) ? shift(@_) : 'CyberSource::SOAP::Lite::Item';
    Any::Moose::load_class($klass)
          unless Any::Moose::is_class_loaded($klass);
    $self->add_item($klass->new($_)) for @_;
}

1;
__END__

=head1 NAME

CyberSource::SOAP::Lite

=head1 SYNOPSIS

  use CyberSource::SOAP::Lite;
  # see t/client.t

  use constant MERCHANT_ID      => ''; # fix this
  use constant TRANSACTION_KEY  => ''; # fix this

  use constant ACCOUNT_NUMBER   => '';
  use constant EXPIRATION_YEAR  => 0;
  use constant EXPIRATION_MONTH => 0;
  use constant CV_NUMBER        => 0;  # security code

  my $soap = CyberSource::SOAP::Lite->new(
      merchant_id             => MERCHANT_ID,
      transaction_key         => TRANSACTION_KEY,
      merchant_reference_code => 123456,               # fix this
      cybs_host               => 'ics2wstest.ic3.com', # for test
      #logging                 => sub { print @_ }
  );

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
      ipAddress  => '11.22.33.44'
  });

  $soap->append_field(shipTo => {
      firstName  => '桂',
      lastName   => '岩佐',
      postalCode => '150-0002',
      street1    => '渋谷区渋谷3-1-11',
      street2    => '',
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

  $soap->checkout(sub {
      my $reply = shift;
  });


=head1 DESCRIPTION

CyberSource::SOAP::Lite is yet another CyberSource's SOAP API.

=head1 AUTHOR

Taiyoh Tanaka E<lt>sun.basix@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
