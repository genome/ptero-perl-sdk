package Ptero::Builder::Detail::HasWebhooksInParameters;
use Moose::Role;
use warnings FATAL => 'all';

use Params::Validate qw(validate_pos :types);

has webhooks => (
    is => 'rw',
    isa => 'HashRef[Str | ArrayRef[Str]]',
    predicate => 'has_webhooks',
);

requires 'from_hashref';

around 'from_hashref' => sub {
    my @args = (shift, shift, shift);

    my ($orig, $class, $hashref) = validate_pos(@args, 1, 1, {type => HASHREF});

    my $webhooks = $hashref->{parameters}{webhooks};

    my $self = $class->$orig($hashref, @_);

    $self->webhooks($webhooks) if defined $webhooks;
    return $self;
};

requires 'to_hashref';

around 'to_hashref' => sub {
    my $orig = shift;
    my $self = shift;

    my $hashref = $self->$orig(@_);

    $hashref->{parameters}{webhooks} = $self->webhooks if $self->has_webhooks;
    return $hashref;
};

1;
