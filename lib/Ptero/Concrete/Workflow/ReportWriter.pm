package Ptero::Concrete::Workflow::ReportWriter;

use strict;
use warnings FATAL => 'all';
use Params::Validate qw(validate validate_pos :types);

my $INDENTATION_STR = '. ';
my $FORMAT_LINE = "%15s %10s %20s %13s  %-7s  %s%s\n";

sub new {
    my $class = shift;
    my $handle = shift;

    my $self = {
        handle => $handle,
    };

    return bless $self, $class;
}

sub write_report {
    my $self = shift;
    my $workflow = shift;

    $self->report_on_workflow($workflow);

    my @sorted_tasks = sort {
        $a->{topological_index} <=> $b->{topological_index}}
        (values %{$workflow->{tasks}});
    for my $task (@sorted_tasks) {
        $self->report_on_task($task->{name}, $task, 0, 0);
    }
}

sub report_on_workflow {
    my $self = shift;
    my $workflow = shift;

    my $handle = $self->{handle};

    printf $handle $FORMAT_LINE,
        'TYPE',
        'STATUS',
        'STARTED',
        'DURATION',
        'P-INDEX',
        '',
        'NAME';

    printf $handle $FORMAT_LINE,
        'Workflow',
        $workflow->{status},
        '',
        '',
        '',
        '',
        $workflow->{name};

    return;
}

sub report_on_task {
    my ($self, $task_name, $task, $indent, $color) = @_;
    my $handle = $self->{handle};

    my $parallel_by_str = '';
    if ($task->{parallel_by}) {
        $parallel_by_str = sprintf("parallel-by: %s", $task->{parallel_by});
    }


    my $execution = $task->{executions}->{$color};
    if ($execution) {
        printf $handle $FORMAT_LINE,
            'Task',
            $execution->{status},
            $execution->datetime_started,
            $execution->duration,
            join(', ', $execution->parallel_indexes),
            $INDENTATION_STR x $indent,
            $task_name . ' ' . $parallel_by_str;
    }

    for my $method (@{$task->{methods}}) {
        $self->report_on_method($method, $indent+1, $color);
    }

    for my $child_execution ($task->executions_with_parent_color($color)) {
        for my $method (@{$task->{methods}}) {
            $self->report_on_method($method, $indent+1, $child_execution->{color});
        }
    }
    return;
}

my $DISPLAY_NAMES = {
    'workflow' => 'DAG',
    'shell-command' => 'ShellCommand',
};

sub report_on_method {
    my ($self, $method, $indent, $color) = @_;
    my $handle = $self->{handle};

    return unless exists $method->{executions}->{$color};

    my $execution = $method->{executions}->{$color};
    printf $handle $FORMAT_LINE,
        $DISPLAY_NAMES->{$method->{service}},
        $execution->{status},
        $execution->datetime_started,
        $execution->duration,
        join(', ', $execution->parallel_indexes),
        $INDENTATION_STR x $indent,
        $method->{name};

    my @sorted_tasks = sort {
        $a->{topological_index} <=> $b->{topological_index}}
        (values %{$method->{tasks}});
    for my $task (@sorted_tasks) {
        $self->report_on_task($task->{name}, $task, $indent+1, $color);
    }

    return;
}

1;
