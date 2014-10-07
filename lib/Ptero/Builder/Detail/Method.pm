package Ptero::Builder::Detail::Method;

use Moose::Role;
use warnings FATAL => 'all';

use Data::Dump qw();
use Set::Scalar;
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::HasValidationErrors';
with 'Ptero::Builder::Detail::ConvertsToHashref';

requires 'input_properties';
requires 'output_properties';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has service => (
    is => 'rw',
    isa => 'Str',
);

has parameters => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {{}},
);

has has_unknown_io_properties => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

sub required_parameters {
    # potentially redefined in subclasses
    return ();
}

sub optional_parameters {
    # potentially redefined in subclasses
    return ();
}

sub validation_errors {
    my $self = shift;
    my @errors;

    my $parameters = Set::Scalar->new(keys %{$self->parameters});
    my $required_parameters = Set::Scalar->new($self->required_parameters);
    my $optional_parameters = Set::Scalar->new($self->optional_parameters);
    my $valid_parameters = $required_parameters + $optional_parameters;

    if (my $missing_parameters = $required_parameters - $parameters) {
        push @errors, sprintf("Method (%s) is missing one or more required parameter(s): %s",
            $self->name, Data::Dump::pp($missing_parameters->members));
    }

    if (my $invalid_parameters = $parameters - $valid_parameters) {
        push @errors, sprintf("Method (%s) has one or more invalid parameter(s): %s",
            $self->name, Data::Dump::pp($invalid_parameters->members));
    }

    return @errors;
}

sub validate_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});

    for my $key (qw(service name parameters)) {
        unless (exists $hashref->{$key}) {
            die sprintf("Method hashref must contain key (%s): %s",
                $key, Data::Dump::pp($hashref));
        }
    }

    unless (ref($hashref->{parameters}) eq 'HASH') {
        die sprintf("The 'parameters' entry must be a hashref not (%s): %s",
            ref($hashref->{parameters}), Data::Dump::pp($hashref));
    }
}


1;
