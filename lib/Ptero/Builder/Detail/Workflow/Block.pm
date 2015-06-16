package Ptero::Builder::Detail::Workflow::Block;

use Moose;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);

with 'Ptero::Builder::Detail::Method';

override 'BUILDARGS' => sub {
    my $params = super();
    $params->{service} = 'workflow-block';
    return $params;
};

sub known_input_properties {
    return ();
}

sub has_possible_output_property {
    my ($self, $name) = validate_pos(@_, 1, {type => SCALAR});
    # inputs appear as outputs as well, both are defined via links.
    return 1;
}

sub required_parameters {
    return qw();
}

sub optional_parameters {
    return qw();
}

__PACKAGE__->meta->make_immutable;
