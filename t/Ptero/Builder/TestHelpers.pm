package Ptero::Builder::TestHelpers;

use strict;
use warnings FATAL => 'all';

use Ptero::Builder::ShellCommand;
use Ptero::Builder::Workflow;

use Exporter 'import';
our @EXPORT_OK = qw(
    build_nested_workflow
    build_basic_workflow
    create_basic_task
);

sub echo_test { shift }
sub fail_test { die "on purpose"; }
sub sleep_echo_test { sleep(2); return shift }
sub sleep_fail_test { sleep(2); die "Bad news"; }

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
    $workflow->connect_input(
        source_property => 'A_in',
        destination => $task,
        destination_property => 'A_in',
    );
    $workflow->connect_output(
        source => $task,
        source_property => 'A_out',
        destination_property => 'A_out',
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
            Ptero::Builder::ShellCommand->new(
                name => 'do something',
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
    $workflow->connect_input(
        source_property => 'A_in',
        destination => $task,
        destination_property => 'A_in',
    );
    $workflow->connect_output(
        source => $task,
        source_property => 'A_out',
        destination_property => 'A_out',
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
            Ptero::Builder::ShellCommand->new(
                name => 'do something',
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
