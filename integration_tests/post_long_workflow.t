# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Log::Log4perl qw(:easy);
use Test::Exception;
use Test::More;
use File::Spec;
use Ptero::TestHelper qw(
    repo_relative_path
    get_environment
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::ShellCommand');

setup_logging();
my $workflow = create_echo_workflow();
my $wf_proxy = $workflow->submit( inputs => { 'easy_in' => 'foo', 'try_in' => 'bar' } );

my $concrete_workflow = $wf_proxy->concrete_workflow;
isa_ok($concrete_workflow, 'Ptero::Concrete::Workflow');

$wf_proxy->wait(polling_interval => 1);

is_deeply($wf_proxy->outputs, { 'easy_out' => 'foo', 'try_out' => 'bar' }, 'Got expected outputs');
done_testing();

sub setup_logging {
    my $logging_level = $ENV{PTERO_PERL_SDK_LOGGING_LEVEL} || $INFO;
    Log::Log4perl->easy_init($logging_level);
}

sub write_report {
    my $concrete_workflow = shift;

    my $handle = new IO::Handle;
    STDOUT->autoflush(1);
    $handle->fdopen(fileno(STDOUT), 'w');

    print $handle "\n\n";
    $concrete_workflow->write_report(
        handle => $handle,
        @ARGV,
    );
}

my $count = 0;
sub create_sleep_echo_command {
    $count++;
    return Ptero::Builder::ShellCommand->new(
            name => "echo succeed $count",
            parameters => {
                commandLine => [
                    repo_relative_path('scripts','perl_subroutine_wrapper'),
                    '--package' => 'Ptero::Builder::TestHelpers',
                    '--subroutine' => 'echo_test'],
                environment => get_environment(),
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );
}

sub create_sleep_fail_command {
    $count++;
    return Ptero::Builder::ShellCommand->new(
            name => "echo fail $count",
            parameters => {
                commandLine => [
                    repo_relative_path('scripts','perl_subroutine_wrapper'),
                    '--package' => 'Ptero::Builder::TestHelpers',
                    '--subroutine' => 'echo_fail'],
                environment => get_environment(),
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );
}

sub create_echo_workflow {
    use Ptero::Concrete::Workflow;
    my $workflow = Ptero::Builder::Workflow->new(name => 'test');
    my $sc = Ptero::Builder::ShellCommand->new(
            name => 'do something',
            parameters => {
                commandLine => [
                    repo_relative_path('scripts','perl_subroutine_wrapper'),
                    '--package' => 'Ptero::Builder::TestHelpers',
                    '--subroutine' => 'echo_test'],
                environment => get_environment(),
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );

    my $easy_street = $workflow->create_task(
        name => 'easy street',
        methods => [
            create_sleep_echo_command(),
            create_sleep_echo_command(),
            create_sleep_echo_command(),
            create_sleep_echo_command(),
            create_sleep_echo_command(),
            create_sleep_echo_command(),
            create_sleep_echo_command(),
        ],
    );
    $workflow->connect_input(
        source_property => 'easy_in',
        destination => $easy_street,
        destination_property => 'easy_in',
    );
    $workflow->connect_output(
        source => $easy_street,
        source_property => 'easy_in',
        destination_property => 'easy_out',
    );

    my $try_hard = $workflow->create_task(
        name => 'try try again',
        methods => [
            create_sleep_fail_command(),
            create_sleep_fail_command(),
            create_sleep_fail_command(),
            create_sleep_fail_command(),
            create_sleep_fail_command(),
            create_sleep_fail_command(),
            create_sleep_echo_command(),
        ],
    );
    $workflow->connect_input(
        source_property => 'try_in',
        destination => $try_hard,
        destination_property => 'try_in',
    );
    $workflow->connect_output(
        source => $try_hard,
        source_property => 'try_in',
        destination_property => 'try_out',
    );

    return $workflow;
}

