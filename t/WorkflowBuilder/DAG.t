use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::DAG');

my $operation_methods = [
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
];

my $operations = {
    A => {
        methods => $operation_methods,
    },
    B => {
        methods => $operation_methods,
    },
};

my $edges = [
    {
        source => 'input connector',
        destination => 'A',
        sourceProperty => 'in_a',
        destinationProperty => 'param',
    },
    {
        source => 'input connector',
        destination => 'B',
        sourceProperty => 'in_b',
        destinationProperty => 'param',
    },
    {
        source => 'A',
        destination => 'output connector',
        sourceProperty => 'out_a',
        destinationProperty => 'out_a',
    },
    {
        source => 'B',
        destination => 'output connector',
        sourceProperty => 'out_a',
        destinationProperty => 'out_b',
    },
    {
        source => 'A',
        destination => 'B',
        sourceProperty => 'out_a',
        destinationProperty => 'a_to_b',
    },
];

{
    my $hashref = {
        nodes => $operations,
        edges => $edges,
    };

    my $dag = Ptero::WorkflowBuilder::DAG->from_hashref($hashref, 'some-workflow');

    is_deeply($dag->to_hashref, $hashref, 'round trip hashref to dag');
}

{
    my $child_hashref = {
        nodes => $operations,
        edges => $edges,
    };

    my $parent_hashref = {
        nodes => {'child-workflow' => $child_hashref},
        edges => [
            {
                source => 'input connector',
                destination => 'child-workflow',
                destinationProperty => 'in_a',
                sourceProperty => 'sub_in_a'
            },
            {
                source => 'input connector',
                destination => 'child-workflow',
                destinationProperty => 'in_b',
                sourceProperty => 'sub_in_b'
            },
            {
                source => 'child-workflow',
                destination => 'output connector',
                destinationProperty => 'sub_out_a',
                sourceProperty => 'out_a'
            },
            {
                source => 'child-workflow',
                destination => 'output connector',
                destinationProperty => 'sub_out_b',
                sourceProperty => 'out_b'
            }
        ]
    };

    my $dag = Ptero::WorkflowBuilder::DAG->from_hashref($parent_hashref, 'parent-workflow');

    is_deeply($dag->to_hashref, $parent_hashref,
        'round trip nested hashref to dag');
}

done_testing();
