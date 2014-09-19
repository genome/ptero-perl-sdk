package Ptero::WorkflowBuilder::Detail::Node;
use Moose::Role;
use warnings FATAL => 'all';

requires 'to_hashref';
requires 'from_hashref';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

sub to_json_hashref {
    my $self = shift;
    return $self->to_hashref;
}

sub from_json_hashref {
    my $self = shift;
    return $self->from_hashref;
}

sub input_properties {
    my $self = shift;
    return;
}

sub output_properties {
    my $self = shift;
    return;
}

sub is_input_property {
    my ($self, $property_name) = @_;
    return List::MoreUtils::any {$property_name eq $_} $self->input_properties;
}

sub is_output_property {
    my ($self, $property_name) = @_;
    return List::MoreUtils::any {$property_name eq $_} $self->output_properties;
}

1;

