package Ptero::WorkflowBuilder::Detail::OperationMethod;

use Moose;
use warnings FATAL => 'all';

with 'Ptero::WorkflowBuilder::Detail::Element';

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
    isa => 'HashRef',
    required => 1,
);


sub to_hashref {
    my $self = shift;

    return {
        name       => $self->name,
        submit_url => $self->submit_url,
        parameters => $self->parameters,
    };
}


__PACKAGE__->meta->make_immutable;

