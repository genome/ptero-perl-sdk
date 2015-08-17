package Ptero::Concrete::Workflow::ReportWriter;

use strict;
use warnings FATAL => 'all';
use Params::Validate qw(validate validate_pos :types);
use Ptero::Statuses qw(
    is_abnormal
    is_running
);
use Ptero::Proxy::Workflow::Execution;

my $INDENTATION_STR = '. ';
my $FORMAT_LINE = "%15s %10s %20s %13s  %s%s\n";

sub new {
    my $class = shift;
    my $handle = shift;

    my $self = {
        handle => $handle,
        executions_of_interest => {},
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
    $self->report_on_abnormal_executions();
}

sub write_header {
    my $self = shift;

    $self->printf($FORMAT_LINE,
        'TYPE',
        'STATUS',
        'STARTED',
        'DURATION',
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
            $INDENTATION_STR x $indent,
            $workflow->{name});
    } elsif (scalar(keys %{$workflow->{executions}}) == 0) {
        $self->printf($FORMAT_LINE,
            'Workflow',
            $workflow->{status},
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
    my ($self, $task_name, $task, $indent, $color, $parallel_by) = @_;

    my $execution = $task->{executions}->{$color};

    my $parallel_by_str = '';
    if ($parallel_by) {
        $parallel_by_str = sprintf("[%s]",
            join(', ', $execution->parallel_indexes));
    } elsif ($task->{parallel_by}) {
            $parallel_by_str = sprintf("[parallel-by: %s]", $task->{parallel_by});
    }

    if ($execution) {
        $self->printf($FORMAT_LINE,
            'Task',
            $execution->{status},
            $execution->datetime_started,
            $execution->duration,
            $INDENTATION_STR x $indent,
            $task_name . ' ' . $parallel_by_str);

        if (is_abnormal($execution->{status})) {
            push @{$self->{executions_of_interest}->{task}},
                $execution;
        }
    } elsif (scalar(keys %{$task->{executions}}) == 0) {
        $self->printf($FORMAT_LINE,
            'Task',
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
        $self->report_on_task($task_name, $task, $indent+1,
            $child_execution->{color}, 1);
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
            $INDENTATION_STR x $indent,
            $method->{name});

        for my $wf_proxy (@{$execution->child_workflow_proxies}) {
            my $concrete_workflow = $wf_proxy->concrete_workflow;
            $self->report_on_workflow($concrete_workflow, $indent+1, 0);
        }

        if (is_abnormal($execution->{status}) or
                is_running($execution->{status})) {
            my $service = $method->{service};
            push @{$self->{executions_of_interest}->{$service}},
                $execution;
        }
    } elsif (scalar(keys %{$method->{executions}}) == 0) {
        $self->printf($FORMAT_LINE,
            $DISPLAY_NAMES->{$method->{service}},
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

sub report_on_abnormal_executions {
    my $self = shift;

    return unless scalar(keys %{$self->{executions_of_interest}});

    $self->printf("\n");
    while (my ($service, $executions) =
            each(%{$self->{executions_of_interest}})) {
        for my $execution (@{$executions}) {
            my $proxy = Ptero::Proxy::Workflow::Execution->new(
                $execution->{details_url}
            );
            $self->report_on_execution($proxy, $service);
            $self->printf("\n");
        }
    }
}

my $EXECUTION_REPORT_METHODS = {
    'shell-command' => 'report_on_shell_command_execution',
};

sub report_on_execution {
    my ($self, $proxy, $service) = @_;

    my $accessor = $EXECUTION_REPORT_METHODS->{$service};

    if ($accessor) {
        $self->$accessor($proxy, $service);
    } else {
        $self->report_on_basic_execution($proxy, $service);
    }
}

sub report_on_basic_execution {
    my ($self, $proxy, $service) = @_;

    $self->printf("  status: %s    name: %s\n", 
        $proxy->concrete_execution->{status},
        $proxy->name);
    $self->printf("  service: %s\n", $service);
    $self->printf("  details url: %s\n", $proxy->url);
    my $error = $proxy->data->{error};
    if ($error) {
        $self->printf("  error: %s\n", $error);
    }
}

sub report_on_shell_command_execution {
    my ($self, $proxy, $service) = @_;

    $self->report_on_basic_execution($proxy, $service);

    my $error = $proxy->data->{errorMessage};
    if ($error) {
        $self->printf("  error: %s\n", $error);
    }

    my $exit_code = $proxy->data->{exitCode};
    if ($exit_code) {
        $self->printf("  exit code: %s\n", $exit_code);
    }

    my $stdout = $proxy->data->{stdout};
    if ($stdout) {
        chomp($stdout);
        $self->printf("  stdout:\n%s\n", $stdout);
    }

    my $stderr = $proxy->data->{stderr};
    if ($stderr) {
        chomp($stderr);
        $self->printf("  stderr:\n%s\n", $stderr);
    }
}

1;
