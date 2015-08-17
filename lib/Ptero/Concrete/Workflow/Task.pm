package Ptero::Concrete::Workflow::Task;

use strict;
use warnings FATAL => 'all';

use Ptero::Concrete::Workflow::DAG;
use Ptero::Concrete::Workflow::Method;

my $CLASS_LOOKUP = {
    'shell-command' => 'Ptero::Concrete::Workflow::Method',
    'workflow' => 'Ptero::Concrete::Workflow::DAG',
    'workflow-block' => 'Ptero::Concrete::Workflow::Method',
    'workflow-converge' => 'Ptero::Concrete::Workflow::Method',
};

sub new {
    my ($class, $hashref, $name) = @_;

    my $self = {};
    $self->{name} = $name;
    $self->{id} = $hashref->{id};
    $self->{parallel_by} = $hashref->{parallelBy};
    $self->{topological_index} = $hashref->{topologicalIndex};
    $self->{executions} = {};

    $self->{methods} = [];
    for my $method_data (@{$hashref->{methods}}) {
        my $method_class = $CLASS_LOOKUP->{$method_data->{service}};
        push @{$self->{methods}}, $method_class->new($method_data);
    }

    return bless $self, $class;
}

sub register_with_workflow {
    my ($self, $workflow) = @_;

    $workflow->{task_index}{$self->{id}} = $self;

    for my $method (@{$self->{methods}}) {
        $method->register_with_workflow($workflow);
    }
    return;
}

sub executions_with_parent_color {
    my ($self, $parent_color) = @_;

    my @executions;
    for my $execution (values %{$self->{executions}}) {
        next unless defined $execution->{parent_color};
        if ($execution->{parent_color} == $parent_color) {
            push @executions, $execution;
        }
    }
    return sort {$a->{color} <=> $b->{color}} @executions;
}

1;
