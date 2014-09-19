package Ptero::WorkflowBuilder::Detail::Link;

use Data::Dump qw();
use Moose;
use warnings FATAL => 'all';

with 'Ptero::WorkflowBuilder::Detail::ConvertsToHashref';
with 'Ptero::WorkflowBuilder::Detail::HasValidationErrors';

has source => (
    is => 'rw',
    isa => 'Str',
    default => 'input connector',
    predicate => 'has_source',
);
has destination => (
    is => 'rw',
    isa => 'Str',
    default => 'output connector',
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

sub to_hashref {
    my $self = shift;

    return {
        source => $self->source,
        destination => $self->destination,
        source_property => $self->source_property,
        destination_property => $self->destination_property,
    }
}

sub external_input {
    my $self = shift;
    return $self->source eq 'input connector';
}

sub external_output {
    my $self = shift;
    return $self->source eq 'output connector';
}

sub sort_key {
    my $self = shift;
    return sprintf('%s|%s|%s|%s',
        $self->source, $self->destination,
        $self->source_property, $self->destination_property);
}

sub source_to_string {
    my $self = shift;
    return sprintf('%s.%s',
        $self->source, $self->source_property);
}

sub destination_to_string {
    my $self = shift;
    return sprintf('%s.%s',
        $self->destination, $self->destination_property);
}

sub to_string {
    my $self = shift;
    return sprintf('%s => %s',
        $self->source_to_string, $self->destination_to_string)
}

sub validation_errors {
    my $self = shift;
    my @errors;
    if ($self->source eq $self->destination) {
        push @errors, sprintf(
            'Source and destination operations on link are both named %s',
            Data::Dump::pp($self->source)
        );
    }

    return @errors;
}


__PACKAGE__->meta->make_immutable;
