use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Slurp qw();

use File::Basename qw(dirname);
use lib dirname(dirname(dirname(__FILE__)));
use Ptero::Builder::TestHelpers qw(
    build_nested_workflow
);

my $test_dir = sprintf '%s.d', __FILE__;

use_ok('Ptero::Builder::Workflow');

{
    my $workflow = build_nested_workflow('parent-workflow');
    regenerate_test_data($workflow, 'nested');

    is($workflow->to_json(), get_test_json('nested'), 'nested to_json');
}

{
    my $blessed_json = get_test_json('nested');
    my $workflow = Ptero::Builder::Workflow->from_json($blessed_json, 'some-workflow');
    is($workflow->to_json, $blessed_json, 'nested roundtrip');
}

{
    my $blessed_json = get_test_json('with_inputs');
    my $workflow = Ptero::Builder::Workflow->from_json($blessed_json, 'some-workflow');
    is($workflow->to_json(inputs => {"A_in" => "foo"}), $blessed_json, 'nested with inputs');
}

{
    my $blessed_json = get_test_json('with_parallel_by');
    my $workflow = Ptero::Builder::Workflow->from_json($blessed_json, 'some-workflow');
    is($workflow->to_json, $blessed_json, 'nested with parallelBy');
}

done_testing();

sub get_test_json {
    my $name = shift;
    my $json_filename = File::Spec->join($test_dir, $name . '.json');
    my $blessed_json = File::Slurp::read_file($json_filename);
    chomp($blessed_json);

    return $blessed_json;
}

sub regenerate_test_data {
    my $workflow = shift;
    my $name = shift;
    my $json_filename = File::Spec->join($test_dir, $name . '.json');
    if ($ENV{REGENERATE_TEST_DATA}) {
        File::Slurp::write_file($json_filename, $workflow->to_json() . "\n");
    }
}
