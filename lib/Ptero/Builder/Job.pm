package Ptero::Builder::Job;

use Moose;
use MooseX::Aliases;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::Method';

override 'BUILDARGS' => sub {
    my $params = super();
    $params->{service} = 'job';

    return $params;
};

has service_url => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    alias => 'serviceUrl',
);

around 'to_hashref' => sub {
    my $orig = shift;
    my $self = shift;

    my $hashref = $self->$orig(@_);

    $hashref->{serviceUrl} = $self->service_url;
    return $hashref;
};

sub known_input_properties {
    return ();
}

sub has_possible_output_property {
    return 1;
}

sub required_parameters {
    return qw(
        commandLine
        user
        workingDirectory
    );
}

sub optional_parameters {
    return qw(
        webhooks
        environment
        umask
    );
}

__PACKAGE__->meta->make_immutable;