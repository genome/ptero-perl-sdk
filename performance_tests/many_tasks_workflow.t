# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Ptero::TestHelper qw(
    repo_relative_path
    get_environment
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::ShellCommand');

my $test_input = 'example test input';
my $count = 500;
my $workflow = create_workflow($count);
my $wf_proxy = $workflow->submit(inputs => {'A_in' => $test_input});
$wf_proxy->wait(polling_interval => 1);

my $expected_outputs;
for my $i (1..$count) {
    $expected_outputs->{"Task $i out"} = $test_input;
}
is_deeply($wf_proxy->outputs, $expected_outputs, 'Got expected outputs');

done_testing();


sub shell_command_method {
    my $name = shift;
    my $subroutine = shift;

    return Ptero::Builder::ShellCommand->new(
            name => $name,
            parameters => {
                commandLine => [
                    repo_relative_path('bin','ptero-perl-subroutine-wrapper'),
                    '--package' => 'Ptero::Builder::TestHelpers',
                    '--subroutine' => $subroutine],
                environment => get_environment(),
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );
}

sub create_workflow {
    my $count = shift;

    my $workflow = Ptero::Builder::Workflow->new(name => 'test');

    for my $i (1..$count) {
        my $task = $workflow->create_task(
            name => "Task $i",
            methods => [shell_command_method("method $i", "echo_test")],
        );

        $workflow->connect_input(
            source_property => 'A_in',
            destination => $task,
            destination_property => 'A_in',
        );
        $workflow->connect_output(
            source => $task,
            source_property => 'A_in',
            destination_property => "Task $i out",
        );
    }

    return $workflow;
}
