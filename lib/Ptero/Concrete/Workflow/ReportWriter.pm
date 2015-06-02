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

sub printf {
    my $self = shift;
    return $self->{handle}->printf(@_);
}

sub write_report {
    my $self = shift;
    my $workflow = shift;

    $self->write_header;
    $self->report_on_workflow($workflow, 0, 0);
}

sub write_header {
    my $self = shift;

    $self->printf($FORMAT_LINE,
        'TYPE',
        'STATUS',
        'STARTED',
        'DURATION',
        'P-INDEX',
        '',
        'NAME');

    return
}

sub report_on_workflow {
    my ($self, $workflow, $indent, $color) = @_;

    my $execution = $workflow->{executions}->{$color};
    if ($execution) {
        $self->printf($FORMAT_LINE,
            'Workflow',
            $execution->{status},
            $execution->datetime_started,
            $execution->duration,
            join(', ', $execution->parallel_indexes),
            $INDENTATION_STR x $indent,
            $workflow->{name});
    } elsif (scalar(keys %{$workflow->{executions}}) == 0) {
        $self->printf($FORMAT_LINE,
            'Workflow',
            $workflow->{status},
            '',
            '',
            '',
            $INDENTATION_STR x $indent,
            $workflow->{name});
    }

    my @sorted_tasks = sort {
        $a->{topological_index} <=> $b->{topological_index}}
        (values %{$workflow->{tasks}});
    for my $task (@sorted_tasks) {
        $self->report_on_task($task->{name}, $task, 0, 0);
    }

    return;
}

sub report_on_task {
    my ($self, $task_name, $task, $indent, $color) = @_;

    my $parallel_by_str = '';
    if ($task->{parallel_by}) {
        $parallel_by_str = sprintf("parallel-by: %s", $task->{parallel_by});
    }


    my $execution = $task->{executions}->{$color};
    if ($execution) {
        $self->printf($FORMAT_LINE,
            'Task',
            $execution->{status},
            $execution->datetime_started,
            $execution->duration,
            join(', ', $execution->parallel_indexes),
            $INDENTATION_STR x $indent,
            $task_name . ' ' . $parallel_by_str);
    } elsif (scalar(keys %{$task->{executions}}) == 0) {
        $self->printf($FORMAT_LINE,
            'Task',
            '',
            '',
            '',
            '',
            $INDENTATION_STR x $indent,
            $task_name . ' ' . $parallel_by_str);
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

    if ($method->{executions}->{$color}) {
        my $execution = $method->{executions}->{$color};
        $self->printf($FORMAT_LINE,
            $DISPLAY_NAMES->{$method->{service}},
            $execution->{status},
            $execution->datetime_started,
            $execution->duration,
            join(', ', $execution->parallel_indexes),
            $INDENTATION_STR x $indent,
            $method->{name});
    } elsif (scalar(keys %{$method->{executions}}) == 0) {
        $self->printf($FORMAT_LINE,
            $DISPLAY_NAMES->{$method->{service}},
            '',
            '',
            '',
            '',
            $INDENTATION_STR x $indent,
            $method->{name});
    } else {
        return;
    }

    my @sorted_tasks = sort {
        $a->{topological_index} <=> $b->{topological_index}}
        (values %{$method->{tasks}});
    for my $task (@sorted_tasks) {
        $self->report_on_task($task->{name}, $task, $indent+1, $color);
    }

    return;
}

1;
