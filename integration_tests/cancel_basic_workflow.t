# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Spec;
use Ptero::Test::Utils qw(
    repo_relative_path
    get_environment
    get_test_name
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::Job');

my $test_input = 'example test input';
my $workflow = create_echo_workflow();
my $wf_proxy = $workflow->submit(
    inputs => {'A_in' => $test_input},
    name => get_test_name("cancel_basic_workflow"),
);
$wf_proxy->cancel;
$wf_proxy->wait(polling_interval => 1);
is($wf_proxy->status, 'canceled', 'Got expected (canceled) status');
is_deeply($wf_proxy->outputs, undef, 'Got expected (empty) outputs');
done_testing();

sub create_echo_workflow {
    my $workflow = Ptero::Builder::Workflow->new(name => 'test');
    my $task_a = get_task($workflow, 'A');
    my $task_b = get_task($workflow, 'B');

    $workflow->create_link(
        destination => $task_a,
        data_flow => {
            'A_in' => 'A_in',
        },
    );
    $workflow->create_link(
        source => $task_a,
        destination => $task_b,
        data_flow => {
            'A_in' => 'A_in',
        },
    );
    $workflow->create_link(
        source => $task_b,
        data_flow => {
            'A_in' => 'A_out',
        },
    );

    return $workflow;
}

sub get_task {
    my ($workflow, $task_name) = @_;
    my $sc = Ptero::Builder::Job->new(
            name => 'do something',
            service_url => $ENV{PTERO_PERL_SDK_TEST_SHELL_COMMAND_SERVICE_URL},
            parameters => {
                commandLine => [
                    repo_relative_path('bin','ptero-perl-subroutine-wrapper'),
                    '--package' => 'Ptero::Test::Commands',
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
