use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use WorkflowBuilder::TestHelper qw(
    create_simple_dag
    create_nested_dag
);

use_ok('Ptero::WorkflowBuilder::DAG');

my $simple_dag_hashref = {
    nodes => {
        A => {
            methods => [
                {
                    name => 'shortcut',
                    submitUrl => 'http://ptero-fork/v1/jobs',
                    parameters => {
                        commandLine => ['genome-ptero-wrapper',
                            'command', 'shortcut', 'NullCommand']
                    },
                },
                {
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
                },
            ],
        },
    },
    edges => [
        {
            source => 'A',
            destination => 'output connector',
            sourceProperty => 'out_a',
            destinationProperty => 'out_a',
        },
        {
            source => 'input connector',
            destination => 'A',
            sourceProperty => 'in_a',
            destinationProperty => 'in_a',
        },
    ],
};

{
    my $dag = create_simple_dag('some-workflow');
    is_deeply($dag->to_hashref, $simple_dag_hashref, 'simple_dag created expected hashref output');
}

{
    my $nested_dag_hashref = {
        nodes => {
            'sub-dag' => $simple_dag_hashref,
            A => {
                methods => [
                    {
                        name => 'shortcut',
                        submitUrl => 'http://ptero-fork/v1/jobs',
                        parameters => {
                            commandLine => ['genome-ptero-wrapper',
                                'command', 'shortcut', 'NullCommand']
                        },
                    },
                    {
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
                    },
                ],
            },
        },
        edges => [
            {
                source => 'A',
                destination => 'output connector',
                sourceProperty => 'out_a',
                destinationProperty => 'out_a',
            },
            {
                source => 'input connector',
                destination => 'A',
                sourceProperty => 'in_a',
                destinationProperty => 'in_a',
            },
            {
                source => 'input connector',
                destination => 'sub-dag',
                sourceProperty => 'sub_in_a',
                destinationProperty => 'in_a',
            },
            {
                source => 'sub-dag',
                destination => 'output connector',
                sourceProperty => 'out_a',
                destinationProperty => 'sub_out_a',
            },
        ],
    };

    my $dag = create_nested_dag('parent-dag');
    is_deeply($dag->to_hashref, $nested_dag_hashref,
        'nested dag produces expected hashref');

    $dag->parallel_by([['dag_pb_input']]);
    $nested_dag_hashref->{parallelBy} = [['dag_pb_input']];
    is_deeply($dag->to_hashref, $nested_dag_hashref,
        'nested dag (with parallel_by) produces expected hashref');
}

{
    my $dag = create_simple_dag('multiple-parallel-by');

    $dag->parallel_by([['foo'],['bar','baz']]);

    my @expected_input_properties = sort qw(in_a foo bar baz);
    is_deeply([$dag->input_properties], \@expected_input_properties,
        'parallel_by flattens correctly');

}

done_testing();
