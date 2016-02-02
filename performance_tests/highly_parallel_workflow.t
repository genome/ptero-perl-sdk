# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Ptero::Test::Utils qw(
    repo_relative_path
    get_environment
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::Job');


my $inner_factor = $ENV{PTERO_TEST_INNER_PARALLEL_FACTOR} || 10;
my $outer_factor = $ENV{PTERO_TEST_OUTER_PARALLEL_FACTOR} || 10;
my $inputs_array = create_inputs_array($inner_factor, $outer_factor);

my $workflow = create_outer_workflow();
my $wf_proxy = $workflow->submit(inputs => {'workflow_in' => $inputs_array});

$wf_proxy->wait(polling_interval => 1);
is_deeply($wf_proxy->outputs, {'workflow_out' => $inputs_array},
    'Got expected outputs');

done_testing();


sub create_inputs_array {
    my $inner_factor = shift;
    my $outer_factor = shift;

    my @outer_array;
    for my $outer_count (1..$outer_factor) {
        my @inner_array;
        for my $inner_count (1..$inner_factor) {
            push @inner_array, sprintf("%s-%s", $outer_count, $inner_count);
        }
        push @outer_array, \@inner_array;
    }
    return \@outer_array;
}

sub create_outer_workflow {
    my $task = create_dag_task();

    my $workflow = Ptero::Builder::Workflow->new(name => "Outer DAG");
    $workflow->add_task($task);
    $workflow->add_data_flow(
        source_property => "workflow_in",
        destination => $task,
        destination_property => "dag_in",
    );
    $workflow->add_data_flow(
        source => $task,
        source_property => "dag_out",
        destination_property => "workflow_out",
    );
    return $workflow;
}


sub create_dag_task {
    my $task = Ptero::Builder::Detail::Workflow::Task->new(
        name => "DAG Task",
        methods => [
            create_inner_workflow(),
        ],
    );
    $task->parallel_by("dag_in");
    return $task;
}

sub create_inner_workflow {
    my $task = create_job_task("Job Task", "Echo", "echo_test");

    my $workflow = Ptero::Builder::Workflow->new(name => "Inner DAG");
    $workflow->add_task($task);
    $workflow->add_data_flow(
        source_property => "dag_in",
        destination => $task,
        destination_property => "job_in",
    );
    $workflow->add_data_flow(
        source => $task,
        source_property => "job_in", # because echo_test just echos inputs
        destination_property => "dag_out",
    );
    return $workflow;
}

sub create_job_task {
    my $task_name = shift;
    my $job_name = shift;
    my $subroutine = shift;

    my $task = Ptero::Builder::Detail::Workflow::Task->new(
        name => $task_name,
        methods => [job_method($job_name, $subroutine)],
    );
    $task->parallel_by("job_in");
    return $task;
}

sub job_method {
    my $name = shift;
    my $subroutine = shift;

    return Ptero::Builder::Job->new(
            name => $name,
            service_url => $ENV{PTERO_PERL_SDK_TEST_SHELL_COMMAND_SERVICE_URL},
            parameters => {
                commandLine => [
                    repo_relative_path('bin','ptero-perl-subroutine-wrapper'),
                    '--package' => 'Ptero::Test::Commands',
                    '--subroutine' => $subroutine],
                environment => get_environment(),
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );
}
