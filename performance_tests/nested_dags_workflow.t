# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Ptero::Test::Utils qw(
    repo_relative_path
    get_environment
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::ShellCommand');

my $test_input = 'example test input';
my $count = $ENV{PTERO_TEST_NESTING_FACTOR} || 25;
my $workflow = create_workflow($count);
my $wf_proxy = $workflow->submit(inputs => {'A_in' => $test_input});
$wf_proxy->wait(polling_interval => 1);
is_deeply($wf_proxy->outputs, {'A_in' => $test_input}, 'Got expected outputs');

done_testing();


sub shell_command_method {
    my $name = shift;
    my $subroutine = shift;

    return Ptero::Builder::ShellCommand->new(
            name => $name,
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

sub create_workflow {
    my $count = shift;

    my $method = shell_command_method("shell_command", "echo_test");
    for my $i (1..$count) {
        my $workflow = Ptero::Builder::Workflow->new(name => "DAG $i");
        my $task = $workflow->create_task(
            name => 'A',
            methods => [$method],
        );
        $workflow->add_data_flow(
            source_property => 'A_in',
            destination => $task,
            destination_property => 'A_in',
        );
        $workflow->add_data_flow(
            source => $task,
            source_property => 'A_in',
            destination_property => 'A_in',
        );
        $method = $workflow;
    }

    return $method;
}
