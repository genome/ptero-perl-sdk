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
my $workflow = create_echo_workflow();
my $wf_proxy = $workflow->submit( inputs => { 'A_in' => $test_input } );
$wf_proxy->wait(polling_interval => 1);
is_deeply($wf_proxy->outputs, { 'A_out' => $test_input }, 'Got expected outputs');
done_testing();

sub create_echo_workflow {
    my $workflow = Ptero::Builder::Workflow->new(name => 'test');
    my $sc = Ptero::Builder::ShellCommand->new(
            name => 'do something',
            parameters => {
                commandLine => [
                    repo_relative_path('bin','ptero-perl-subroutine-wrapper'),
                    '--package' => 'Ptero::Builder::TestHelpers',
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
    $workflow->connect_input(
        source_property => 'A_in',
        destination => $task,
        destination_property => 'A_in',
    );
    $workflow->connect_output(
        source => $task,
        source_property => 'A_in',
        destination_property => 'A_out',
    );

    return $workflow;
}

