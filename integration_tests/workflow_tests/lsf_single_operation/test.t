use Ptero::Test::Integration qw(run_test);
use Test::More;

my @required_env = qw(PTERO_PERL_SDK_TEST_LSF_SERVICE_URL
    PTERO_PERL_SDK_TEST_LSF_QUEUE);

my $call_done_testing = 1;
SKIP: {
    skip(join(' and ', @required_env).' must be set to run these tests', 1)
        unless environment_set(@required_env);

    $call_done_testing = 0;
    run_test(__FILE__);
};

done_testing() if $call_done_testing;

sub environment_set {
    foreach my $var (@required_env) {
        return unless exists($ENV{$var}) and defined($ENV{$var});
    }

    return 1;
}
