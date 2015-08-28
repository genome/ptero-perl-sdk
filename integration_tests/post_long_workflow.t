# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Log::Log4perl qw(:easy);
use Test::Exception;
use Test::More;
use File::Spec;
use Ptero::Test::Utils qw(
    repo_relative_path
    get_environment
    get_test_name
    validate_submit_environment
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::Job');

validate_submit_environment();

setup_logging();
my $workflow = create_echo_workflow();
my $wf_proxy = $workflow->submit(
    inputs => {
        'easy_in' => 'foo',
        'try_in' => 'bar'
    },
    name => get_test_name("post_long_workflow"),
);

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
    return Ptero::Builder::Job->new(
            name => "echo succeed $count",
            service_url => $ENV{PTERO_PERL_SDK_TEST_SHELL_COMMAND_SERVICE_URL},
            parameters => {
                commandLine => [
                    repo_relative_path('bin',
                        'ptero-perl-subroutine-wrapper'),
                    '--package' => 'Ptero::Test::Commands',
                    '--subroutine' => 'echo_test'],
                environment => get_environment(),
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );
}

sub create_sleep_fail_command {
    $count++;
    return Ptero::Builder::Job->new(
            name => "echo fail $count",
            service_url => $ENV{PTERO_PERL_SDK_TEST_SHELL_COMMAND_SERVICE_URL},
            parameters => {
                commandLine => [
                    repo_relative_path('bin','ptero-perl-subroutine-wrapper'),
                    '--package' => 'Ptero::Test::Commands',
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
    $workflow->create_link(
        destination => $easy_street,
        data_flow => {
            'easy_in' => 'easy_in',
        },
    );
    $workflow->create_link(
        source => $easy_street,
        data_flow => {
            'easy_in' => 'easy_out',
        },
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
    $workflow->add_data_flow(
        source_property => 'try_in',
        destination => $try_hard,
        destination_property => 'try_in',
    );
    $workflow->add_data_flow(
        source => $try_hard,
        source_property => 'try_in',
        destination_property => 'try_out',
    );

    return $workflow;
}

