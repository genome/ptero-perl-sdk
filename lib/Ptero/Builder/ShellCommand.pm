package Ptero::Builder::ShellCommand;

use Moose;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::Method';

override 'BUILDARGS' => sub {
    my $params = super();
    $params->{service} = 'ShellCommand';
    $params->{has_unknown_io_properties} = 1;
    return $params;
};

sub input_properties {
    my $self = shift;
    return ();
}

sub output_properties {
    my $self = shift;
    return ();
}

sub required_parameters {
    return qw(
        commandLine
    );
}

sub optional_parameters {
    return qw(
        environment
        umask
        user
    );
}

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});

    $class->validate_hashref($hashref);
    return $class->new(%$hashref);
}

sub to_hashref {
    my $self = shift;

    return {
        name => $self->name,
        service => $self->service,
        parameters => $self->parameters,
    };
}

__PACKAGE__->meta->make_immutable;
