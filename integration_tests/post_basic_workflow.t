# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Ptero::Test::Utils qw(
    repo_relative_path
    get_environment
    get_test_name
    validate_submit_environment
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::Job');

validate_submit_environment();

my $test_input = 'example test input';
my $workflow = create_echo_workflow();
my $wf_proxy = $workflow->submit(
    inputs => {'A_in' => $test_input},
    name => get_test_name("post_basic_workflow"),
);
$wf_proxy->wait(polling_interval => 1);
is_deeply($wf_proxy->outputs, { 'A_out' => $test_input }, 'Got expected outputs');
done_testing();

sub create_echo_workflow {
    my $workflow = Ptero::Builder::Workflow->new(name => 'test');
    my $sc = Ptero::Builder::Job->new(
            name => 'do something',
            service_url => $ENV{PTERO_PERL_SDK_TEST_SHELL_COMMAND_SERVICE_URL},
            parameters => {
                commandLine => [
                    repo_relative_path('bin','ptero-perl-subroutine-wrapper'),
                    '--package' => 'Ptero::Test::Commands',
                    '--subroutine' => 'echo_test'],
                environment => get_environment(),
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );
    my $task = $workflow->create_task(
        name => 'A',
        methods => [$sc],
    );
    $workflow->create_link(
        destination => $task,
        data_flow => {
            'A_in' => 'A_in',
        },
    );
    $workflow->create_link(
        source => $task,
        data_flow => {
            'A_in' => 'A_out',
        },
    );

    return $workflow;
}

