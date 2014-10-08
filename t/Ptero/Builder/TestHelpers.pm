package Ptero::Builder::TestHelpers;

use strict;
use warnings FATAL => 'all';

use Ptero::Builder::ShellCommand;
use Ptero::Builder::Detail::Task;
use Ptero::Builder::DAG;

use Exporter 'import';
our @EXPORT_OK = qw(
    build_nested_dag
    build_basic_dag
    create_basic_task
);

sub build_nested_dag {
    my $name = shift;

    my $dag = Ptero::Builder::DAG->new(name => $name);
    my $task = $dag->create_task(
        name => 'A',
        methods => [
            build_basic_dag('inner'),
        ],
    );
    $dag->connect_input(
        source_property => 'A_in',
        destination => $task,
        destination_property => 'A_in',
    );
    $dag->connect_output(
        source => $task,
        source_property => 'A_out',
        destination_property => 'A_out',
    );
    return $dag;
}

sub build_basic_dag {
    my $name = shift;

    my $dag = Ptero::Builder::DAG->new(name => $name);
    my $task = $dag->create_task(
        name => 'A',
        methods => [
            Ptero::Builder::ShellCommand->new(
                name => 'do something',
                parameters => {
                    commandLine => ['echo', 'basic-dag'],
                },
            ),
        ],
    );
    $dag->connect_input(
        source_property => 'A_in',
        destination => $task,
        destination_property => 'A_in',
    );
    $dag->connect_output(
        source => $task,
        source_property => 'A_out',
        destination_property => 'A_out',
    );
    return $dag;
}

sub create_basic_task {
    my $dag = shift;
    my $name = shift;

    return $dag->create_task(
        name => $name,
        methods => [
            Ptero::Builder::ShellCommand->new(
                name => 'do something',
                parameters => {
                    commandLine => ['echo', 'basic-task'],
                },
            ),
        ],
    );
}

1;
