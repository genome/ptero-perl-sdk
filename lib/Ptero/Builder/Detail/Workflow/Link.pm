package Ptero::Builder::Detail::Workflow::Link;

use Moose;
use MooseX::Aliases;
use Moose::Util::TypeConstraints;
use Ptero::Builder::Detail::Workflow::Task;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);
use List::MoreUtils qw(uniq);
use Set::Scalar;

with 'Ptero::Builder::Detail::HasValidationErrors';

subtype 'Ptero::Builder::Detail::Workflow::TaskName' => as 'Str';

coerce 'Ptero::Builder::Detail::Workflow::TaskName',
    from 'Ptero::Builder::Detail::Workflow::Task',
    via { $_->name };

has source => (
    is => 'rw',
    isa => 'Ptero::Builder::Detail::Workflow::TaskName',
    default => 'input connector',
    predicate => 'has_source',
    coerce => 1,
);

has destination => (
    is => 'rw',
    isa => 'Ptero::Builder::Detail::Workflow::TaskName',
    default => 'output connector',
    predicate => 'has_destination',
    coerce => 1,
);

has data_flow => (
    is => 'rw',
    isa => 'HashRef[ArrayRef[Str]]',
    predicate => 'has_data_flow',
);

sub BUILDARGS {
    my ($class, %args) = @_;

    if ($args{dataFlow}) {
        $args{data_flow} = delete $args{dataFlow};
    }

    if ($args{data_flow}) {
        my %data_flow = %{$args{data_flow}};
        for my $source_property (keys %data_flow) {
            unless (ref($data_flow{$source_property})) {
                $data_flow{$source_property} = [$data_flow{$source_property}];
            }
        }
        $args{data_flow} = \%data_flow;
    }
    return \%args;
}

sub is_external_input {
    my $self = shift;
    return $self->source eq 'input connector';
}

sub is_external_output {
    my $self = shift;
    return $self->destination eq 'output connector';
}

sub add_data_flow {
    my ($self, $source_property, $destination_property) = @_;

    my $new_data_flow = $self->has_data_flow ? $self->data_flow : {};

    my $destinations = $new_data_flow->{$source_property} || [];
    push @$destinations, $destination_property;
    $new_data_flow->{$source_property} = [uniq @$destinations];

    $self->data_flow($new_data_flow);
    return $self->data_flow;
}

sub source_properties {
    my $self = shift;

    if ($self->has_data_flow) {
        return keys %{$self->data_flow};
    } else {
        return ();
    }
}

sub destination_properties {
    my $self = shift;

    my $property_names = Set::Scalar->new();
    if ($self->has_data_flow) {
        for my $destination_arrayref (values %{$self->data_flow}) {
            $property_names->insert(@$destination_arrayref);
        }
        return $property_names->members();
    } else {
        return ();
    }
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
    return sprintf('Ptero::Builder::Detail::Workflow::Link(source => %s, destination => %s, data_flow => %s)',
        Data::Dump::pp($self->source),
        Data::Dump::pp($self->destination),
        Data::Dump::pp($self->data_flow),
    );
}

sub to_hashref {
    my $self = shift;

    my $result = {
        source => $self->source,
        destination => $self->destination,
    };
    if ($self->has_data_flow) {
        $result->{dataFlow} = $self->formatted_data_flow;
    }
    return $result;
}

sub formatted_data_flow {
    my $self = shift;

    my $result = {};
    for my $source_property (keys(%{$self->data_flow})) {
        my $destination_arrayref = $self->data_flow->{$source_property};
        if (scalar(@$destination_arrayref) > 1) {
            $result->{$source_property} = $destination_arrayref;
        } else {
            $result->{$source_property} = $destination_arrayref->[0];
        }
    }
    return $result;
}

__PACKAGE__->meta->make_immutable;
