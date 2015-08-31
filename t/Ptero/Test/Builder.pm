package Ptero::Test::Builder;

use strict;
use warnings FATAL => 'all';

use Ptero::Builder::Job;
use Ptero::Builder::Workflow;

use Exporter 'import';
our @EXPORT_OK = qw(
    build_nested_workflow
    build_basic_workflow
    create_basic_task
);

sub build_nested_workflow {
    my $name = shift;

    my $workflow = Ptero::Builder::Workflow->new(name => $name);
    my $task = $workflow->create_task(
        name => 'A',
        methods => [
            build_basic_workflow('inner'),
        ],
        webhooks => {
            scheduled => 'http://localhost:8080/example/task/scheduled',
            failed => 'http://localhost:8080/example/task/failed',
            succeeded => ['http://localhost:8080/example/task/succeeded', 'http://localhost:8080/congrats']
        },
    );
    $workflow->create_link(
        destination => $task,
        data_flow => {
            'A_in' => 'A_in',
        }
    );
    $workflow->create_link(
        source => $task,
        data_flow => {
            'A_out' => 'A_out',
        }
    );
    $workflow->webhooks( {
        scheduled => 'http://localhost:8080/example/outer/scheduled',
        failed => 'http://localhost:8080/example/outer/failed',
        succeeded => ['http://localhost:8080/example/outer/succeeded', 'http://localhost:8080/congrats']
    } );
    return $workflow;
}

sub build_basic_workflow {
    my $name = shift;

    my $workflow = Ptero::Builder::Workflow->new(name => $name);
    my $task = $workflow->create_task(
        name => 'A',
        methods => [
            Ptero::Builder::Job->new(
                name => 'do something',
                service_url => 'http://example.com/v1',
                parameters => {
                    commandLine => ['echo', 'basic-workflow'],
                    user => 'testuser',
                    workingDirectory => '/test/working/directory',
                    webhooks => {
                        scheduled => 'http://localhost:8080/example/shellcmd/scheduled',
                        failed => 'http://localhost:8080/example/shellcmd/failed',
                        succeeded => ['http://localhost:8080/example/shellcmd/succeeded', 'http://localhost:8080/yay']
                    }
                },
            ),
        ],
        webhooks => {
            scheduled => 'http://localhost:8080/example/task/scheduled',
            failed => 'http://localhost:8080/example/task/failed',
            succeeded => ['http://localhost:8080/example/task/succeeded', 'http://localhost:8080/congrats']
        },
    );
    $workflow->create_link(
        destination => $task,
        data_flow => {
            'A_in' => 'A_in',
        }
    );
    $workflow->create_link(
        source => $task,
        data_flow => {
            'A_out' => 'A_out',
        }
    );
    $workflow->webhooks( {
        scheduled => 'http://localhost:8080/example/workflow/scheduled',
        failed => 'http://localhost:8080/example/workflow/failed',
        succeeded => ['http://localhost:8080/example/workflow/succeeded', 'http://localhost:8080/congrats']
    } );
    return $workflow;
}

sub create_basic_task {
    my $workflow = shift;
    my $name = shift;

    return $workflow->create_task(
        name => $name,
        methods => [
            Ptero::Builder::Job->new(
                name => 'do something',
                service_url => 'http://example.com/v1',
                parameters => {
                    commandLine => ['echo', 'basic-task'],
                    user => 'testuser',
                    workingDirectory => '/test/working/directory',
                },
            ),
        ],
    );
}

1;
