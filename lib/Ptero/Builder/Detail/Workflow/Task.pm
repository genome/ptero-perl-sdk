package Ptero::Builder::Detail::Workflow::Task;

use Moose;
use MooseX::Aliases;
use warnings FATAL => 'all';

use Data::Dump qw();
use Set::Scalar qw();
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::HasValidationErrors';
with 'Ptero::Builder::Detail::ConvertsToHashref';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has methods => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::Builder::Detail::Method]',
    default => sub { [] },
);

has parallel_by => (
    is => 'rw',
    isa => 'Str',
    alias => 'parallelBy',
    predicate => 'has_parallel_by',
);

sub add_method {
    my ($self, $method) = @_;
    $self->methods([@{$self->methods}, $method]);
    return $method;
}

sub known_input_properties {
    my $self = shift;

    my $properties = Set::Scalar->new();
    if ($self->has_parallel_by) {
        $properties->insert($self->parallel_by);
    }

    for my $method (@{$self->methods}) {
        $properties->insert($method->known_input_properties);
    }

    return $properties->members;
}

sub has_possible_output_property {
    my ($self, $name) = validate_pos(@_, 1, 1);

    my $result = 1;
    for my $method (@{$self->methods}) {
        $result = $result && $method->has_possible_output_property($name);
    }
    return $result;
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

sub from_hashref {
    my ($class, $hashref, $name) = validate_pos(@_, 1, {type => HASHREF}, {type => SCALAR});

    unless (exists $hashref->{methods} && ref($hashref->{methods}) eq 'ARRAY') {
        die 'Task hashref must contain a methods arrayref: '
            . Data::Dump::pp($hashref);
    }


    my @methods;
    for my $method_hashref (@{$hashref->{methods}}) {
        my $method_class = method_class_from_hashref($method_hashref);
        push @methods, $method_class->from_hashref($method_hashref);
    }
    my %params = (
        name => $name,
        methods => \@methods,
    );

    if (exists $hashref->{parallelBy}) {
        $params{parallel_by} = $hashref->{parallelBy};
    }

    return $class->new(%params);
}

my $lookup = {
    'shell-command' => 'Ptero::Builder::ShellCommand',
    'workflow' => 'Ptero::Builder::Workflow',
};

sub method_class_from_hashref {
    my $hashref = shift;

    my $service = $hashref->{service};
    if (exists $lookup->{$service}) {
        return $lookup->{$service};
    } else {
        die sprintf("Could not determine method class from hashref: %s",
            Data::Dump::pp($hashref));
    }
}

sub to_hashref {
    my $self = shift;

    my $hashref = {
        methods => [map {$_->to_hashref} @{$self->methods}],
    };
    if ($self->has_parallel_by) {
        $hashref->{parallelBy} = $self->parallel_by;
    }

    return $hashref;
}


__PACKAGE__->meta->make_immutable;
