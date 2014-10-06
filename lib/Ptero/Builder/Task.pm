package Ptero::Builder::Task;

use Moose;
use MooseX::Aliases;
use warnings FATAL => 'all';

use Data::Dump qw();
use Set::Scalar qw();
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::HasValidationErrors';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has methods => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::Builder::Method]',
    default => sub { [] },
);

has parallel_by => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Str]]',
    alias => 'parallelBy',
    predicate => 'has_parallel_by',
);

sub add_method {
    my ($self, $method) = validate_pos(@_, 1, {type=>OBJECT});
    push @{$self->methods}, $method;
    return $method;
}

sub input_properties {
    my $self = shift;

    my $properties = Set::Scalar->new();
    $properties-> insert($self->parallel_by_properties);

    for my $method (@{$self->methods}) {
        $properties->insert($method->input_properties);
    }

    return $properties->members;
}

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

sub output_properties {
    my $self = shift;

    my $properties = Set::Scalar->new();

    for my $method (@{$self->methods}) {
        $properties->insert($method->output_properties);
    }

    return $properties->members;
}


sub validation_errors {
    my $self = shift;

    my @errors = map { $self->$_ } qw(
        _name_errors
        _method_errors
    );
    for my $method (@{$self->methods}) {
        push @errors, $method->validation_errors;
    }

    return @errors;
}

my $_INVALID_NAMES = new Set::Scalar('input connector', 'output connector');

sub _name_errors {
    my $self = shift;
    my @errors;

    if ($_INVALID_NAMES->contains($self->name)) {
        push @errors, sprintf(
            'Task may not be named %s',
            Data::Dump::pp($self->name)
        );
    }

    return @errors;
}

sub _method_errors {
    my $self = shift;
    my @errors;

    my @methods = @{$self->methods};
    unless (@methods) {
        push @errors, sprintf(
            'Task named %s must have at least one method',
            Data::Dump::pp($self->name)
        );
    }

    return @errors;
}


__PACKAGE__->meta->make_immutable;
