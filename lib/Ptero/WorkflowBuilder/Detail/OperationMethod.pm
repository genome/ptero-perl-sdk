package Procera::WorkflowBuilder::Detail::OperationMethod;

use Moose::Role;
use warnings FATAL => 'all';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has submit_url => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has parameters => (
    is => 'rw',
    isa => 'HashRef[Defined]',
    required => 1,
);

sub from_hashref {
    my ($class, $hashref) = @_;

    return $class->new(%$hashref);
}

sub to_hashref {
    my $self = shift;

    return {
        name       => $self->name,
        submit_url => $self->submit_url,
        parameters => $self->parameters,
    };
}

1;

