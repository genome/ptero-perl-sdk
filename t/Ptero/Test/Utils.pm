package Ptero::Test::Utils;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT_OK = qw(
    validate_submit_environment
    validate_execution_environment
    repo_relative_path
    get_environment
);

my @EXPECTED_SUBMIT_ENV_VARIABLES = qw(
    PTERO_WORKFLOW_SUBMIT_URL
    PTERO_PERL_SDK_HOME
);

my @EXPECTED_EXECUTION_ENV_VARIABLES = qw(
    PTERO_WORKFLOW_EXECUTION_URL
    PTERO_WORKFLOW_SUBMIT_URL
);

sub validate_submit_environment {
    my $validated = 1;
    for my $env_var (@EXPECTED_SUBMIT_ENV_VARIABLES) {
        unless (defined $ENV{$env_var}) {
            printf STDERR "Environment Variable %s must be set before workflow submission.\n", $env_var;
            $validated = 0;
        }
    }

    exit 1 unless $validated;
    return;
}

sub validate_execution_environment {
    my $validated = 1;
    for my $env_var (@EXPECTED_EXECUTION_ENV_VARIABLES) {
        unless (defined $ENV{$env_var}) {
            printf STDERR "Environment Variable %s must be set before method execution\n", $env_var;
            $validated = 0;
        }
    }

    exit 1 unless $validated;
    return;
}

sub repo_relative_path {
    my $home = $ENV{PTERO_PERL_SDK_HOME};
    return File::Spec->join($home, @_);
}

sub get_environment {
    my %env = %ENV;
    $env{PERL5LIB} = join(':', $env{PERL5LIB},
        repo_relative_path('lib'),
        repo_relative_path('t'));
    return \%env;
}


1;
