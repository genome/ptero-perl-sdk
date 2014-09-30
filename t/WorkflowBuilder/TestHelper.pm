package WorkflowBuilder::TestHelper;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT_OK = qw(
    create_simple_dag
    create_nested_dag
    create_task
);

sub create_task {
    my $name = shift;

    my $methods = [
        Ptero::WorkflowBuilder::Detail::Method->new(
            name => 'shortcut',
            submitUrl => 'http://ptero-fork/v1/jobs',
            parameters => {
                commandLine => ['genome-ptero-wrapper',
                    'command', 'shortcut', 'NullCommand']
            },
        ),
        Ptero::WorkflowBuilder::Detail::Method->new(
            name => 'execute',
            submitUrl => 'http://ptero-lsf/v1/jobs',
            parameters => {
                commandLine => ['genome-ptero-wrapper',
                    'command', 'execute', 'NullCommand'],
                limit => {
                    virtual_memory => 204800,
                },
                request => {
                    min_cores => 4,
                    memory => 200,
                    temp_space => 5,
                },
                reserve => {
                    min_cores => 4,
                    memory => 200,
                    temp_space => 5,
                },
            },
        ),
    ];
    return Ptero::WorkflowBuilder::Task->new(
        name => $name,
        methods => $methods,
    );
}

sub create_simple_dag {
    my $name = shift;

    my $task = create_task('A');
    my $dag = Ptero::WorkflowBuilder::DAG->new(
        name => $name,
        nodes => [$task],
    );
    $dag->connect_input(
        source_property => 'in_a',
        destination => $task,
        destination_property => 'in_a',
    );
    $dag->connect_output(
        source => $task,
        source_property => 'out_a',
        destination_property => 'out_a',
    );
    return $dag;
}

sub create_nested_dag {
    my $name = shift;

    my $sub_dag = create_simple_dag('sub-dag');
    my $parent_dag = create_simple_dag('parent-dag');

    $parent_dag->add_node($sub_dag);
    $parent_dag->connect_input(
        source_property => 'sub_in_a',
        destination => $sub_dag,
        destination_property => 'in_a',
    );
    $parent_dag->connect_output(
        source => $sub_dag,
        source_property => 'out_a',
        destination_property => 'sub_out_a',
    );
    return $parent_dag;
}


1;
