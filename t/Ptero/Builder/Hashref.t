use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::Builder::TestHelpers qw(
    build_nested_workflow
    build_basic_workflow
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
                            parameters => {
                                commandLine => ["echo", "basic-workflow"],
                                user => 'testuser',
                                workingDirectory => '/test/working/directory',
                            },
                            service => "shell-command",
                        },
                    ],
                },
            },
        },
        service => "workflow",
    };

    my $workflow = build_basic_workflow('foo');
    is_deeply($workflow->to_hashref, $expected_hashref, 'basic_workflow hashref');
    is_deeply(Ptero::Builder::Workflow->from_hashref($expected_hashref)->to_hashref,
        $expected_hashref, 'basic_workflow hashref roundtrip');
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
                            parameters => {
                                commandLine => ["echo", "basic-workflow"],
                                user => 'testuser',
                                workingDirectory => '/test/working/directory',
                            },
                            service => "shell-command",
                        },
                    ],
                    parallelBy => [["A_in"]],
                },
            },
        },
        service => "workflow",
    };

    my $workflow = build_basic_workflow('foo');
    $workflow->task_named('A')->parallel_by([['A_in']]);

    is_deeply($workflow->to_hashref, $expected_hashref, 'basic_workflow parallel_by hashref');
    is_deeply(Ptero::Builder::Workflow->from_hashref($expected_hashref)->to_hashref,
        $expected_hashref, 'basic_workflow parallel_by hashref roundtrip');
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
                                                parameters => {
                                                    commandLine => ["echo", "basic-workflow"],
                                                    user => 'testuser',
                                                    workingDirectory => '/test/working/directory',
                                                },
                                                service => "shell-command",
                                            },
                                        ],
                                    },
                                },
                            },
                            service => "workflow",
                        },
                    ],
                },
            },
        },
        service => "workflow",
    };

    my $workflow = build_nested_workflow('foo');
    is_deeply($workflow->to_hashref, $expected_hashref, 'nested_workflow hashref');
    is_deeply(Ptero::Builder::Workflow->from_hashref($expected_hashref)->to_hashref,
        $expected_hashref, 'nested_workflow hashref roundtrip');
}

done_testing();
