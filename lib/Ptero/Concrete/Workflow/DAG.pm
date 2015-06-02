package Ptero::Concrete::Workflow::DAG;

use strict;
use warnings FATAL => 'all';

sub new {
    my ($class, $hashref) = @_;

    my $self = {};
    $self->{id} = $hashref->{id};
    $self->{name} = $hashref->{name};
    $self->{service} = $hashref->{service};
    $self->{executions} = {};

    while (my ($key, $val) = each %{$hashref->{parameters}{tasks}}) {
        $self->{tasks}{$key} = Ptero::Concrete::Workflow::Task->new(
            $val, $key);
    }

    return bless $self, $class;
}

sub register_with_workflow {
    my ($self, $workflow) = @_;

    $workflow->{method_index}{$self->{id}} = $self;

    for my $task (values %{$self->{tasks}}) {
        $task->register_with_workflow($workflow);
    }
    return;
}

1;
