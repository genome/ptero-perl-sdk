package Ptero::WorkflowBuilder::Link;

use Moose;
use warnings FATAL => 'all';

with 'Ptero::WorkflowBuilder::Detail::Element';

has source => (
    is => 'rw',
    isa => 'Object',
    predicate => 'has_source',
);
has destination => (
    is => 'rw',
    isa => 'Object',
    predicate => 'has_destination',
);

has source_property => (
    is => 'rw',
    isa => 'Str',
);
has destination_property => (
    is => 'rw',
    isa => 'Str',
);

# ------------------------------------------------------------------------------
# Inherited Methods
# ------------------------------------------------------------------------------

sub to_hashref {
    my $self = shift;
    return {
        source => $self->source_operation_name,
        destination => $self->destination_operation_name,
        source_property => $self->source_property,
        destination_property => $self->destination_property,
    }
}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------

sub destination_operation_name {
    my $self = shift;
    return $self->_operation_name('destination', 'output connector');
}

sub source_operation_name {
    my $self = shift;
    return $self->_operation_name('source', 'input connector');
}

sub external_input {
    my $self = shift;
    return !$self->has_source;
}

sub external_output {
    my $self = shift;
    return !$self->has_destination;
}

sub sort_key {
    my $self = shift;
    return sprintf("%s|%s|%s|%s",
        $self->source_operation_name, $self->destination_operation_name,
        $self->source_property, $self->destination_property);
}

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

sub _operation_name {
    my ($self, $operation, $default) = @_;

    my $predicate = sprintf('has_%s', $operation);
    if ($self->$predicate) {
        return $self->$operation->name;
    } else {
        return $default;
    }
}


__PACKAGE__->meta->make_immutable;
