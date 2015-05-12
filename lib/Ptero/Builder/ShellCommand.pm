package Ptero::Builder::ShellCommand;

use Moose;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::Method';

override 'BUILDARGS' => sub {
    my $params = super();
    $params->{service} = 'shell-command';
    return $params;
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
