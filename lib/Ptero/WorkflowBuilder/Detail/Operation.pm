package Ptero::WorkflowBuilder::Detail::Operation;

use Moose;
use warnings FATAL => 'all';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);


__PACKAGE__->meta->make_immutable;
