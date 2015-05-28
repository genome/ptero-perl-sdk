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

    my $task_data = $hashref->{parameters}{tasks};
    for my $task_name (keys %$task_data) {
        $self->{tasks}{$task_name} = Ptero::Concrete::Workflow::Task->new(
            $task_data->{$task_name}, $task_name);
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
