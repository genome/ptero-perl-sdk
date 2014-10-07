use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::Builder::TestHelpers qw(
    build_nested_dag
    build_basic_dag
);

{
    my $expected_hashref = {
        name => "foo",
        parameters => {
            links => [
                {
                    destination => "A",
                    destinationProperty => "A_in",
                    source => "input connector",
                    sourceProperty => "A_in",
                },
                {
                    destination => "output connector",
                    destinationProperty => "A_out",
                    source => "A",
                    sourceProperty => "A_out",
                },
            ],
            tasks => {
                A => {
                    methods => [
                        {
                            name => "do something",
                            parameters => { commandLine => ["echo", "basic-dag"] },
                            service => "ShellCommand",
                        },
                    ],
                },
            },
        },
        service => "Workflow",
    };

    my $dag = build_basic_dag('foo');
    is_deeply($dag->to_hashref, $expected_hashref, 'basic_dag hashref');
    is_deeply(Ptero::Builder::DAG->from_hashref($expected_hashref)->to_hashref,
        $expected_hashref, 'basic_dag hashref roundtrip');
}

{
    my $expected_hashref = {
        name => "foo",
        parameters => {
            links => [
                {
                    destination => "A",
                    destinationProperty => "A_in",
                    source => "input connector",
                    sourceProperty => "A_in",
                },
                {
                    destination => "output connector",
                    destinationProperty => "A_out",
                    source => "A",
                    sourceProperty => "A_out",
                },
            ],
            tasks => {
                A => {
                    methods => [
                        {
                            name => "do something",
                            parameters => { commandLine => ["echo", "basic-dag"] },
                            service => "ShellCommand",
                        },
                    ],
                    parallelBy => [["A_in"]],
                },
            },
        },
        service => "Workflow",
    };

    my $dag = build_basic_dag('foo');
    $dag->task_named('A')->parallel_by([['A_in']]);

    is_deeply($dag->to_hashref, $expected_hashref, 'basic_dag parallel_by hashref');
    is_deeply(Ptero::Builder::DAG->from_hashref($expected_hashref)->to_hashref,
        $expected_hashref, 'basic_dag parallel_by hashref roundtrip');
}

{
    my $expected_hashref = {
        name => "foo",
        parameters => {
            links => [
                {
                    destination => "A",
                    destinationProperty => "A_in",
                    source => "input connector",
                    sourceProperty => "A_in",
                },
                {
                    destination => "output connector",
                    destinationProperty => "A_out",
                    source => "A",
                    sourceProperty => "A_out",
                },
            ],
            tasks => {
                A => {
                    methods => [
                        {
                            name => "inner",
                            parameters => {
                                links => [
                                    {
                                        destination => "A",
                                        destinationProperty => "A_in",
                                        source => "input connector",
                                        sourceProperty => "A_in",
                                    },
                                    {
                                        destination => "output connector",
                                        destinationProperty => "A_out",
                                        source => "A",
                                        sourceProperty => "A_out",
                                    },
                                ],
                                tasks => {
                                    A => {
                                        methods => [
                                            {
                                                name => "do something",
                                                parameters => { commandLine => ["echo", "basic-dag"] },
                                                service => "ShellCommand",
                                            },
                                        ],
                                    },
                                },
                            },
                            service => "Workflow",
                        },
                    ],
                },
            },
        },
        service => "Workflow",
    };

    my $dag = build_nested_dag('foo');
    is_deeply($dag->to_hashref, $expected_hashref, 'nested_dag hashref');
    is_deeply(Ptero::Builder::DAG->from_hashref($expected_hashref)->to_hashref,
        $expected_hashref, 'nested_dag hashref roundtrip');
}

done_testing();
