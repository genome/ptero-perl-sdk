package Ptero::WorkflowBuilder::Detail::Method;

use Moose;
use MooseX::Aliases;
use warnings FATAL => 'all';

with 'Ptero::WorkflowBuilder::Detail::ConvertsToHashref';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has submit_url => (
    is => 'rw',
    isa => 'Str',
    alias => 'submitUrl',
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
        submitUrl  => $self->submit_url,
        parameters => $self->parameters,
    };
}


__PACKAGE__->meta->make_immutable;

