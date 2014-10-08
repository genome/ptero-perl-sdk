package Ptero::Builder::Detail::Link;

use Moose;
use MooseX::Aliases;
use Moose::Util::TypeConstraints;
use Ptero::Builder::Detail::Task;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::HasValidationErrors';

subtype 'Ptero::Builder::Detail::TaskName' => as 'Str';

coerce 'Ptero::Builder::Detail::TaskName',
    from 'Ptero::Builder::Detail::Task',
    via { $_->name };

has source => (
    is => 'rw',
    isa => 'Ptero::Builder::Detail::TaskName',
    default => 'input connector',
    predicate => 'has_source',
    coerce => 1,
);

has destination => (
    is => 'rw',
    isa => 'Ptero::Builder::Detail::TaskName',
    default => 'output connector',
    predicate => 'has_destination',
    coerce => 1,
);

has source_property => (
    is => 'rw',
    isa => 'Str',
    alias => 'sourceProperty',
);

has destination_property => (
    is => 'rw',
    isa => 'Str',
    alias => 'destinationProperty',
);

sub is_external_input {
    my $self = shift;
    return $self->source eq 'input connector';
}

sub is_external_output {
    my $self = shift;
    return $self->destination eq 'output connector';
}

sub validation_errors {
    my $self = shift;

    return map { $self->$_ } qw(
        _source_and_destination_unique_errors
        _source_is_output_connector_errors
        _destination_is_input_connector_errors
    );
}

sub _source_and_destination_unique_errors {
    my $self = shift;

    if ($self->source eq $self->destination) {
        return sprintf(
            'Source and destination tasks on link are both named %s',
            Data::Dump::pp($self->source)
        );
    } else {
        return ();
    }
}

sub _source_is_output_connector_errors {
    my $self = shift;

    if ($self->source eq 'output connector') {
        return 'Source cannot be named named "output connector"';
    } else {
        return ();
    }
}

sub _destination_is_input_connector_errors {
    my $self = shift;

    if ($self->destination eq 'input connector') {
        return 'Destination cannot be named named "input connector"';
    } else {
        return ();
    }
}

sub to_string {
    my $self = shift;
    return sprintf('Ptero::Builder::Detail::Link(source => %s, source_property => %s, destination => %s, destination_property => %s)',
        Data::Dump::pp($self->source),
        Data::Dump::pp($self->source_property),
        Data::Dump::pp($self->destination),
        Data::Dump::pp($self->destination_property),
    );
}

sub to_hashref {
    my $self = shift;

    return {
        source => $self->source,
        sourceProperty => $self->source_property,
        destination => $self->destination,
        destinationProperty => $self->destination_property,
    };
}

__PACKAGE__->meta->make_immutable;
