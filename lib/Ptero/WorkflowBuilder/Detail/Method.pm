package Ptero::WorkflowBuilder::Detail::Method;

use Moose;
use MooseX::Aliases;
use warnings FATAL => 'all';

use Data::Dump qw();
use Params::Validate qw(validate validate_pos :types);
use Set::Scalar;

with 'Ptero::WorkflowBuilder::Detail::ConvertsToHashref';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has service => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has parameters => (
    is => 'rw',
    isa => 'HashRef',
    required => 1,
);

has constant_parameters => (
    is => 'rw',
    isa => 'HashRef',
    alias => 'constantParameters',
    predicate => 'has_constant_parameters',
);

has parent_method => (
    is => 'rw',
    isa => 'Ptero::WorkflowBuilder::Detail::Method',
    predicate => 'has_parent_method',
    clearer => 'clear_parent_method',
);

has _parameter_calculation_method => (
    is => 'rw',
    isa => 'Ptero::WorkflowBuilder::Detail::Method',
    predicate => 'has_parameter_calculation_method',
    clearer => 'clear_parameter_calculation_method',
);

sub set_parameter_calculation_method {
    my ($self, $method) = validate_pos(@_, 1, 1);

    if ($method->has_parent_method) {
        die sprintf("Method (%s) is already calculating properties for method (%s)",
            $method->name, $method->parent_method->name);
    }

    if ($self->lineage->member($method)) {
        die sprintf("Method (%s) is a part of the lineage containing: %s",
            $method->name, Data::Dump::pp(map {$_->name} $self->lineage->members));
    }

    if ($self->has_parameter_calculation_method) {
        my $old_method = $self->_parameter_calculation_method;
        $old_method->clear_parent_method;
    }

    $method->parent_method($self);
    $self->_parameter_calculation_method($method);
    return $method;
}

sub lineage {
    my $self = shift;

    my $result = Set::Scalar->new($self);

    my $target = $self;
    while ($target->has_parent_method) {
        my $parent = $target->parent_method;
        $result->insert($parent);
        $target = $parent;
    }
    return $result;
}

sub unset_parameter_calculation_method {
    my $self = shift;

    my $old_method = $self->_parameter_calculation_method;
    $old_method->clear_parent_method;
    $self->clear_parameter_calculation_method;

    return $old_method;
}

sub to_hashref {
    my $self = shift;

    my $result ={
        name       => $self->name,
        service => $self->service,
        parameters => $self->parameters,
    };
    if ($self->has_parameter_calculation_method) {
        $result->{'parameterCalculationMethod'} =
            $self->_parameter_calculation_method->to_hashref;
    }
    if ($self->has_constant_parameters) {
        $result->{'constantParameters'} = $self->constant_parameters;
    }
    return $result;
}

sub from_hashref {
    my ($class, $hashref) = @_;

    my %working_hashref = %$hashref;

    my $child_hashref = delete $working_hashref{parameterCalculationMethod};
    my $self = Ptero::WorkflowBuilder::Detail::Method->new(%working_hashref);
    if ($child_hashref) {
        $self->set_parameter_calculation_method(
            Ptero::WorkflowBuilder::Detail::Method->from_hashref($child_hashref)
        );
    }
    return $self;
}

sub validation_errors {
    my $self = shift;
    my @errors;

    my $parameters = Set::Scalar->new(keys %{$self->parameters});
    my $constants = Set::Scalar->new(keys %{$self->constant_parameters});

    my $intersection = $parameters->intersection($constants);
    if ($intersection) {
        push @errors, sprintf(
            'Method (%s) has a key collision %s between parameters and constant_parameters',
            $self->name, Data::Dump::pp($intersection->members),
        );
    }

    return @errors;
}


__PACKAGE__->meta->make_immutable;
