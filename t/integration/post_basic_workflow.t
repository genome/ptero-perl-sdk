# vim: ft=perl
use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Spec;

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::ShellCommand');


my $workflow = Ptero::Builder::Workflow->new(name => 'test');
my $sc = Ptero::Builder::ShellCommand->new(
        name => 'do something',
        parameters => {
            commandLine => [
                repo_relative_path('bin','perl_subroutine_wrapper'),
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
my $wf_proxy = $workflow->submit( inputs => { 'A_in' => 'example input' } );
ok($wf_proxy);
diag($wf_proxy->url);
done_testing();

sub repo_relative_path {
    return File::Spec->join($ENV{PTERO_PERL_SDK_TEST_HOME}, @_);
}

sub get_environment {
    my %env = %ENV;
    $env{PERL5LIB} = join(':', $env{PERL5LIB},
        repo_relative_path('lib'),
        repo_relative_path('t'));
    return \%env;
}
