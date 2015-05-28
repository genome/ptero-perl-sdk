package Ptero::Concrete::Workflow;

use strict;
use warnings FATAL => 'all';
use Params::Validate qw(validate validate_pos :types);

use Ptero::Concrete::Workflow::Task;
use Ptero::Concrete::Workflow::Execution;

sub new {
    my ($class, $hashref) = @_;

    my $self = {};
    $self->{id} = $hashref->{id};
    $self->{root_task_id} = $hashref->{rootTaskId};
    $self->{name} = $hashref->{name};
    $self->{status} = $hashref->{status};
    $self->{method_index} = {};
    $self->{task_index} = {};

    my $task_data = $hashref->{tasks};
    for my $task_name (keys %$task_data) {
        $self->{tasks}{$task_name} = Ptero::Concrete::Workflow::Task->new(
            $task_data->{$task_name}, $task_name);
    }

    return bless $self, $class;
}

sub register_components {
    my $self = shift;

    for my $task (values %{$self->{tasks}}) {
        $task->register_with_workflow($self);
    }
    return;
}

sub create_executions {
    my ($self, $execution_hashrefs) = @_;

    for my $hashref (@{$execution_hashrefs}) {
        my $execution = Ptero::Concrete::Workflow::Execution->new($hashref);
        my $parent_index = sprintf("%s_index", $execution->{parent_type});
        my $parent = $self->{$parent_index}{$execution->{parent_id}};
        $parent->{executions}->{$execution->{color}} = $execution;
    }
}

1;
