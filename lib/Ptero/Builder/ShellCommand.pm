package Ptero::Builder::ShellCommand;

use Moose;
use warnings FATAL => 'all';

with 'Ptero::Builder::Detail::Method';

override 'BUILDARGS' => sub {
    my $params = super();
    $params->{service} = 'ShellCommand';
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


__PACKAGE__->meta->make_immutable;
