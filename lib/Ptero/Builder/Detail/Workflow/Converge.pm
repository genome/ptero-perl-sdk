package Ptero::Builder::Detail::Workflow::Converge;

use Moose;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::Method';

override 'BUILDARGS' => sub {
    my $params = super();
    $params->{service} = 'workflow-converge';
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
        input_names
        output_name
    );
}

sub optional_parameters {
    return qw();
}

__PACKAGE__->meta->make_immutable;
