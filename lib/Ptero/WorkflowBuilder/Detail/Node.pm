package Ptero::WorkflowBuilder::Detail::Node;
use Moose::Role;
use warnings FATAL => 'all';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

sub input_properties {
    my $self = shift;

    return;
}

1;

