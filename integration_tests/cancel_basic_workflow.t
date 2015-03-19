# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Spec;
use Ptero::TestHelper qw(
    repo_relative_path
    get_environment
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::ShellCommand');

my $test_input = 'example test input';
my $workflow = create_echo_workflow();
my $wf_proxy = $workflow->submit( inputs => { 'A_in' => $test_input } );
$wf_proxy->cancel;
$wf_proxy->wait(polling_interval => 1);
is($wf_proxy->status, 'canceled', 'Got expected (canceled) status');
is_deeply($wf_proxy->outputs, undef, 'Got expected (empty) outputs');
done_testing();

sub create_echo_workflow {
    my $workflow = Ptero::Builder::Workflow->new(name => 'test');
    my $task_a = get_task($workflow, 'A');
    my $task_b = get_task($workflow, 'B');

    $workflow->connect_input(
        source_property => 'A_in',
        destination => $task_a,
        destination_property => 'A_in',
    );
    $workflow->link_tasks(
        source => $task_a,
        destination => $task_b,
        source_property => 'A_in',
        destination_property => 'A_in',
    );
    $workflow->connect_output(
        source => $task_b,
        source_property => 'A_in',
        destination_property => 'A_out',
    );

    return $workflow;
}

sub get_task {
    my ($workflow, $task_name) = @_;
    my $sc = Ptero::Builder::ShellCommand->new(
            name => 'do something',
            parameters => {
                commandLine => [
                    repo_relative_path('bin','ptero-perl-subroutine-wrapper'),
                    '--package' => 'Ptero::Builder::TestHelpers',
                    '--subroutine' => 'sleep_echo_test'],
                environment => get_environment(),
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );
    return $workflow->create_task(
        name => $task_name,
        methods => [$sc],
    );
}
