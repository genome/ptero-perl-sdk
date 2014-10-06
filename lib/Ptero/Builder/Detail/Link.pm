package Ptero::Builder::Detail::Link;

use Moose;
use MooseX::Aliases;
use Moose::Util::TypeConstraints;
use Ptero::Builder::Task;
use warnings FATAL => 'all';

with 'Ptero::Builder::Detail::HasValidationErrors';

subtype 'Ptero::Builder::TaskName' => as 'Str';

coerce 'Ptero::Builder::TaskName',
    from 'Ptero::Builder::Task',
    via { $_->name };

has source => (
    is => 'rw',
    isa => 'Ptero::Builder::TaskName',
    default => 'input connector',
    predicate => 'has_source',
    coerce => 1,
);

has destination => (
    is => 'rw',
    isa => 'Ptero::Builder::TaskName',
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

sub validation_errors {
    my $self = shift;
    my @errors;
    if ($self->source eq $self->destination) {
        push @errors, sprintf(
            'Source and destination tasks on link are both named %s',
            Data::Dump::pp($self->source)
        );
    }

    return @errors;
}


__PACKAGE__->meta->make_immutable;
