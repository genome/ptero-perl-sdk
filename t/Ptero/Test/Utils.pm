package Ptero::Test::Utils;

use strict;
use warnings FATAL => 'all';
use Data::UUID qw();
use File::Slurp qw(read_file write_file);
use File::Basename qw(basename);
use Test::More;
use Text::Diff qw(diff);

use Exporter 'import';
our @EXPORT_OK = qw(
    validate_submit_environment
    validate_execution_environment
    repo_relative_path
    get_environment
    get_test_name
    process_into_markdown
    filter
    is_same
);

sub get_test_name {
    my $base_name = shift;

    my $generator = Data::UUID->new();
    my $uuid = $generator->create();
    return sprintf("Perl SDK Integration Test (%s) %s",
        $base_name, $generator->to_string($uuid));
}

my @EXPECTED_SUBMIT_ENV_VARIABLES = qw(
    PTERO_WORKFLOW_SUBMIT_URL
    PTERO_PERL_SDK_HOME
    PTERO_PERL_SDK_TEST_SHELL_COMMAND_SERVICE_URL
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
    my $home = $ENV{PTERO_PERL_SDK_HOME} || die "Must specify PTERO_PERL_SDK_HOME";
    return File::Spec->join($home, @_);
}

sub get_environment {
    my %env = %ENV;
    $env{PERL5LIB} = join(':', $env{PERL5LIB},
        repo_relative_path('lib'),
        repo_relative_path('t'));
    return \%env;
}

sub process_into_markdown {
    my $infile = shift;

    my $CAPTURE_MODE_REGEX = qr/^\s*#<<(.*)/;
    my $MARKDOWN_REGEX = qr/^\s*#\|(.*)/;

    my $capture_mode = 0;
    my $result = '';
    for my $line (read_file($infile)) {
        if ($capture_mode) {
            if ($line =~ m/$CAPTURE_MODE_REGEX/) {
                $result .= "```\n\n";
                $capture_mode = 0;
            } else {
                $result .= $line;
            }
        } else {
            if ($line =~ m/$CAPTURE_MODE_REGEX/) {
                $result .= "\n\n```$1\n";
                $capture_mode = 1;
            } else {
                if ($line =~ m/$MARKDOWN_REGEX/) {
                    $result .= $1 . "\n";
                }
            }
        }
    }

    my $outfile = repo_relative_path('docs', 'examples', basename($infile));
    $outfile =~ s/t$/md/;
    write_file($outfile, $result);
}

sub filter {
    my $string = shift;
    my $regex = shift;

    return join("\n", grep {!($_ =~ $regex)} split(/\n/, $string)) . "\n";
}

sub is_same {
    my ($got, $expected, $label) = @_;

    my $filtered_expected = filter($expected, qr(^\s*#));
    my $diff = diff(\$got, \$filtered_expected, { STYLE => "Context" });

    my $rv = ok(!$diff, $label);
    unless ($rv) {
        printf "Found differences:\n"
        ."*** => got\n--- => expected\n%s", $diff;
    }
    return $rv;
}

1;
