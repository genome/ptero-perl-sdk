package WorkflowBuilder::TestHelper;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT_OK = qw(
    create_simple_dag
    create_nested_dag
);

sub create_operation {
    my $name = shift;

    my $operation_methods = [
        Ptero::WorkflowBuilder::Detail::OperationMethod->new(
            name => 'shortcut',
            submitUrl => 'http://ptero-fork/v1/jobs',
            parameters => {
                commandLine => ['genome-ptero-wrapper',
                    'command', 'shortcut', 'NullCommand']
            },
        ),
        Ptero::WorkflowBuilder::Detail::OperationMethod->new(
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
    return Ptero::WorkflowBuilder::Operation->new(
        name => $name,
        methods => $operation_methods,
    );
}

sub create_simple_dag {
    my $name = shift;

    my $op = create_operation('A');
    my $dag = Ptero::WorkflowBuilder::DAG->new(
        name => $name,
        nodes => [$op],
    );
    $dag->connect_input(
        source_property => 'in_a',
        destination => $op,
        destination_property => 'in_a',
    );
    $dag->connect_output(
        source => $op,
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
