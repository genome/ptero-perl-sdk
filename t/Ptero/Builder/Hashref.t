use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use File::Basename qw(dirname);
use lib dirname(dirname(dirname(__FILE__)));
use Ptero::Test::Builder qw(
    build_nested_workflow
    build_basic_workflow
);

{
    my $expected_hashref = {
        name => "foo",
        parameters => {
            links => [
                {
                    source => "input connector",
                    destination => "A",
                    dataFlow => {
                        A_in => "A_in",
                    },
                },
                {
                    source => "A",
                    destination => "output connector",
                    "dataFlow" => {
                        A_out => "A_out",
                    },
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
                            service => "job",
                            serviceUrl => 'http://example.com/v1',
                            webhooks => {
                                scheduled => 'http://localhost:8080/example/shellcmd/scheduled',
                                failed => 'http://localhost:8080/example/shellcmd/failed',
                                succeeded => ['http://localhost:8080/example/shellcmd/succeeded', 'http://localhost:8080/yay']
                            },
                        },
                    ],
                    webhooks => {
                        scheduled => 'http://localhost:8080/example/task/scheduled',
                        failed => 'http://localhost:8080/example/task/failed',
                        succeeded => ['http://localhost:8080/example/task/succeeded', 'http://localhost:8080/congrats']
                    },
                },
            },
        },
        service => "workflow",
        webhooks => {
            scheduled => 'http://localhost:8080/example/workflow/scheduled',
            failed => 'http://localhost:8080/example/workflow/failed',
            succeeded => ['http://localhost:8080/example/workflow/succeeded', 'http://localhost:8080/congrats']
        },
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
                    source => "input connector",
                    destination => "A",
                    dataFlow => {
                        A_in => "A_in",
                    },
                },
                {
                    source => "A",
                    destination => "output connector",
                    dataFlow => {
                        A_out => "A_out",
                    },
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
                            service => "job",
                            serviceUrl => 'http://example.com/v1',
                            webhooks => {
                                scheduled => 'http://localhost:8080/example/shellcmd/scheduled',
                                failed => 'http://localhost:8080/example/shellcmd/failed',
                                succeeded => ['http://localhost:8080/example/shellcmd/succeeded', 'http://localhost:8080/yay']
                            },
                        },
                    ],
                    parallelBy => "A_in",
                    webhooks => {
                        scheduled => 'http://localhost:8080/example/task/scheduled',
                        failed => 'http://localhost:8080/example/task/failed',
                        succeeded => ['http://localhost:8080/example/task/succeeded', 'http://localhost:8080/congrats']
                    },
                },
            },
        },
        service => "workflow",
        webhooks => {
            scheduled => 'http://localhost:8080/example/workflow/scheduled',
            failed => 'http://localhost:8080/example/workflow/failed',
            succeeded => ['http://localhost:8080/example/workflow/succeeded', 'http://localhost:8080/congrats']
        },
    };

    my $workflow = build_basic_workflow('foo');
    $workflow->task_named('A')->parallel_by('A_in');

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
                    source => "input connector",
                    destination => "A",
                    dataFlow => {
                        A_in => "A_in",
                    },
                },
                {
                    source => "A",
                    destination => "output connector",
                    dataFlow => {
                        A_out => "A_out",
                    },
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
                                        source => "input connector",
                                        destination => "A",
                                        dataFlow => {
                                            A_in => "A_in",
                                        },
                                    },
                                    {
                                        source => "A",
                                        destination => "output connector",
                                        dataFlow => {
                                            A_out => "A_out",
                                        },
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
                                                service => "job",
                                                serviceUrl => 'http://example.com/v1',
                                                webhooks => {
                                                    scheduled => 'http://localhost:8080/example/shellcmd/scheduled',
                                                    failed => 'http://localhost:8080/example/shellcmd/failed',
                                                    succeeded => ['http://localhost:8080/example/shellcmd/succeeded', 'http://localhost:8080/yay']
                                                },
                                            },
                                        ],
                                        webhooks => {
                                            scheduled => 'http://localhost:8080/example/task/scheduled',
                                            failed => 'http://localhost:8080/example/task/failed',
                                            succeeded => ['http://localhost:8080/example/task/succeeded', 'http://localhost:8080/congrats']
                                        },
                                    },
                                },
                            },
                            service => "workflow",
                            webhooks => {
                                scheduled => 'http://localhost:8080/example/workflow/scheduled',
                                failed => 'http://localhost:8080/example/workflow/failed',
                                succeeded => ['http://localhost:8080/example/workflow/succeeded', 'http://localhost:8080/congrats']
                            },
                        },
                    ],
                    webhooks => {
                        scheduled => 'http://localhost:8080/example/task/scheduled',
                        failed => 'http://localhost:8080/example/task/failed',
                        succeeded => ['http://localhost:8080/example/task/succeeded', 'http://localhost:8080/congrats']
                    },
                },
            },
        },
        service => "workflow",
        webhooks => {
            scheduled => 'http://localhost:8080/example/outer/scheduled',
            failed => 'http://localhost:8080/example/outer/failed',
            succeeded => ['http://localhost:8080/example/outer/succeeded', 'http://localhost:8080/congrats']
        },
    };

    my $workflow = build_nested_workflow('foo');
    is_deeply($workflow->to_hashref, $expected_hashref, 'nested_workflow hashref');
    is_deeply(Ptero::Builder::Workflow->from_hashref($expected_hashref)->to_hashref,
        $expected_hashref, 'nested_workflow hashref roundtrip');
}

done_testing();
