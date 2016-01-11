package Ptero::Concrete::Workflow;

use strict;
use warnings FATAL => 'all';
use Params::Validate qw(validate validate_pos :types);
use IO::String;

use Ptero::Concrete::Workflow::Task;
use Ptero::Concrete::Workflow::Execution;
use Ptero::Concrete::Workflow::ReportWriter;

sub new {
    my ($class, $hashref) = @_;

    my $self = bless {}, $class;
    $self->{id} = $hashref->{id};
    $self->{root_task_id} = $hashref->{rootTaskId};
    $self->{name} = $hashref->{name};
    $self->{status} = $hashref->{status};
    $self->{method_index} = {};
    $self->{task_index} = {};

    while (my ($key, $val) = each %{$hashref->{tasks}}) {
        $self->{tasks}{$key} = Ptero::Concrete::Workflow::Task->new(
            $val, $key);
    }

    $self->register_components();

    return $self;
}

sub register_components {
    my $self = shift;

    for my $task (values %{$self->{tasks}}) {
        $task->register_with_workflow($self);
    }
    return;
}

sub add_executions {
    my ($self, $executions) = @_;

    for my $execution (@{$executions}) {
        if ($execution->{parent_id} == $self->{root_task_id} && $execution->{parent_type} eq 'task') {
            $self->{executions}{$execution->{color}} = $execution
        } else {
            my $parent_index = sprintf("%s_index", $execution->{parent_type});
            my $parent = $self->{$parent_index}{$execution->{parent_id}};
            next unless $parent;
            $parent->{executions}->{$execution->{color}} = $execution;
        }

    }
}

sub view_as_string {
    my $self = shift;

    my $result;
    my $handle = new IO::String($result);

    my $report_writer = Ptero::Concrete::Workflow::ReportWriter->new($handle);
    $report_writer->write_report($self);
    return $result;
}

sub print_view {
    my $self = shift;

    my $handle = new IO::Handle;
    STDOUT->autoflush(1);
    $handle->fdopen(fileno(STDOUT), 'w');

    my $report_writer = Ptero::Concrete::Workflow::ReportWriter->new($handle);
    $report_writer->write_report($self);
    return;
}

1;
