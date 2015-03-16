package Ptero::TestHelper;

use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON qw(to_json from_json);
use File::Slurp qw(read_file);
use IO::File;
use File::Temp qw(tempfile);
use File::Basename qw(dirname);
use File::Spec qw();
use Template;
use Ptero::Builder::Workflow;
use Ptero::Builder::ShellCommand;

use Exporter 'import';
our @EXPORT_OK = qw(
    run_test
    repo_relative_path
    get_environment
);

sub run_test {
    my $file = shift;

    validate_environment();

    my $dir = dirname($file);

    my $submit_file = File::Spec->join($dir, 'submit.json');
    my $workflow_json = _get_workflow_json($submit_file);
    my $workflow = Ptero::Builder::Workflow->from_json($workflow_json, 'some-test-workflow');

    my $wf_proxy = $workflow->submit(inputs => get_workflow_inputs($workflow_json));
    $wf_proxy->wait(polling_interval => 1);

    my $result_file = File::Spec->join($dir, 'result.json');
    is_deeply($wf_proxy->outputs, get_expected_outputs($result_file), 'Got expected outputs');

    done_testing();
}

sub validate_environment {
    unless (defined $ENV{PTERO_WORKFLOW_SUBMIT_URL}) {
        die "Environment variable PTERO_WORKFLOW_SUBMIT_URL must be set";
    }
}

sub get_workflow_inputs {
    my $workflow_json = shift;

    my $hashref = from_json($workflow_json);
    return $hashref->{inputs} || die "Couldn't find inputs in file '$workflow_json'";
}

sub get_expected_outputs {
    my $filename = shift;

    my $json_text = read_file($filename);
    my $hashref = from_json($json_text);
    return $hashref->{outputs} || die "No outputs found in file '$filename'";
}

sub repo_relative_path {
    my $home = $ENV{PTERO_PERL_SDK_HOME} || die "You must set PTERO_PERL_SDK_HOME";
    return File::Spec->join($home, @_);
}

sub get_environment {
    my %env = %ENV;
    $env{PERL5LIB} = join(':', $env{PERL5LIB},
        repo_relative_path('lib'),
        repo_relative_path('t'));
    return \%env;
}

sub _get_workflow_json {
    my $submit_file = shift;

    my $template = Template->new({
        START_TAG => quotemeta('{{'),
        END_TAG   => quotemeta('}}'),
    });

    my $vars = {
        user => $ENV{USER},
        environment => to_json(get_environment()),
        workingDirectory => repo_relative_path('bin'),
    };

    my $in_fh = IO::File->new("< $submit_file");

    my $workflow_json;
    $template->process($in_fh, $vars, \$workflow_json)
        || die $template->error();

    return $workflow_json;
}

1;
