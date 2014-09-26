package Ptero::WorkflowBuilder::Command;

use Moose;
use warnings FATAL => 'all';

use Data::Dump qw();
use Set::Scalar qw();
use Params::Validate qw(validate_pos :types);

use Ptero::WorkflowBuilder::Detail::Method;

with 'Ptero::WorkflowBuilder::Detail::ConvertsToHashref';
with 'Ptero::WorkflowBuilder::Detail::HasValidationErrors';
with 'Ptero::WorkflowBuilder::Detail::Node';

has methods => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Detail::Method]',
    default => sub { [] },
);

sub is_input_property {
    my ($self, $property_name) = @_;

    return 1;
}

sub is_output_property {
    my ($self, $property_name) = @_;

    return 1;
}

sub to_hashref {
    my $self = shift;

    my $result = {
        methods => [map { $_->to_hashref } @{$self->methods}],
    };
    if ($self->has_parallel_by) {
        $result->{parallelBy} = $self->parallel_by;
    }
    return $result;
}

sub from_hashref {
    my ($class, $hashref, $name) = validate_pos(@_, 1,
        {type => HASHREF}, {type => SCALAR});

    unless (exists $hashref->{methods} && ref($hashref->{methods}) eq 'ARRAY') {
        die 'Command hashref must contain a methods arrayref: '
            . Data::Dump::pp($hashref);
    }

    my %hash = %$hashref; # copy the hashref

    my @methods = map {
        Ptero::WorkflowBuilder::Detail::Method->from_hashref($_)
    } @{$hashref->{methods}};

    delete $hash{methods};

    return $class->new(%hash, methods => \@methods, name => $name);
}

my $_INVALID_NAMES = new Set::Scalar('input connector', 'output connector');
sub validation_errors {
    my $self = shift;
    my @errors;

    if ($_INVALID_NAMES->contains($self->name)) {
        push @errors, sprintf(
            'Command may not be named %s',
            Data::Dump::pp($self->name)
        );
    }

    my @methods = @{$self->methods};
    unless (@methods) {
        push @errors, sprintf(
            'Command named %s must have at least one method',
            Data::Dump::pp($self->name)
        );
    }

    return @errors;
}


__PACKAGE__->meta->make_immutable;
