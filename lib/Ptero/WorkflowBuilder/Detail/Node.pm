package Ptero::WorkflowBuilder::Detail::Node;
use Moose::Role;
use MooseX::Aliases;
use warnings FATAL => 'all';

requires 'to_hashref';
requires 'from_hashref';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has parallel_by => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Str]]',
    alias => 'parallelBy',
    predicate => 'has_parallel_by',
);

sub parallel_by_properties {
    my $self = shift;

    return unless $self->has_parallel_by;

    my @flattened_properties;
    for my $group (@{$self->parallel_by}) {
        for my $property (@$group) {
            push @flattened_properties, $property;
        }
    }
    return @flattened_properties;
}

sub input_properties {
    my $self = shift;

    my @properties;
    push @properties, $self->parallel_by_properties;

    return @properties;
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

