package Ptero::Concrete::Workflow::Method;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($class, $hashref) = @_;

    my $self = {};
    $self->{id} = $hashref->{id};
    $self->{name} = $hashref->{name};
    $self->{service} = $hashref->{service};
    $self->{executions} = {};

    # only Job Methods have serviceUrl
    if (exists $hashref->{serviceUrl}) {
        $self->{serviceUrl} = $hashref->{serviceUrl};

        if (exists $hashref->{serviceDataToSave}) {
            $self->{serviceDataToSave} = $hashref->{serviceDataToSave};
        }
    }

    return bless $self, $class;
}

sub register_with_workflow {
    my ($self, $workflow) = @_;

    $workflow->{method_index}{$self->{id}} = $self;
    return;
}

1;
