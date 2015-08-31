use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Slurp qw();
use Text::Diff qw(diff);

use File::Basename qw(dirname);
use lib dirname(dirname(dirname(__FILE__)));
use Ptero::Test::Builder qw(
    build_nested_workflow
);

my $test_dir = sprintf '%s.d', __FILE__;

use_ok('Ptero::Builder::Workflow');

{
    my $workflow = build_nested_workflow('parent-workflow');
    regenerate_test_data($workflow, 'nested');

    is_same($workflow->to_json(), get_test_file('nested'), 'nested to_json');
}

{
    my $blessed_json = get_test_json('nested');
    my $workflow = Ptero::Builder::Workflow->from_json($blessed_json, 'some-workflow');
    is_same($workflow->to_json, get_test_file('nested'), 'nested roundtrip');
}

{
    my $blessed_json = get_test_json('with_inputs');
    my $workflow = Ptero::Builder::Workflow->from_json($blessed_json, 'some-workflow');
    is_same($workflow->to_json({"A_in" => "foo"}), get_test_file('with_inputs'),
        'nested with inputs');
}

{
    my $blessed_json = get_test_json('with_parallel_by');
    my $workflow = Ptero::Builder::Workflow->from_json($blessed_json, 'some-workflow');
    is_same($workflow->to_json, get_test_file('with_parallel_by'),
        'nested with parallelBy');
}

{
    my $blessed_json = get_test_json('block_and_converge');
    my $workflow = Ptero::Builder::Workflow->from_json($blessed_json, 'some-workflow');
    is_same($workflow->to_json, get_test_file('block_and_converge'),
        'block and converge');
}

done_testing();

sub get_test_file {
    my $name = shift;
    return File::Spec->join($test_dir, $name . '.json');
}

sub get_test_json {
    my $name = shift;
    my $json_filename = get_test_file($name);
    my $blessed_json = File::Slurp::read_file($json_filename);
    chomp($blessed_json);

    return $blessed_json;
}

sub regenerate_test_data {
    my $workflow = shift;
    my $name = shift;
    my $json_filename = File::Spec->join($test_dir, $name . '.json');
    if ($ENV{REGENERATE_TEST_DATA}) {
        File::Slurp::write_file($json_filename, $workflow->to_json());
    }
}

sub is_same {
    my ($got, $expected_file, $label) = @_;

    my $diff = diff($expected_file, \$got, { STYLE => "Context" });
    ok(!$diff, $label) || printf "Found differences:\n"
        ."*** => generated string\n--- => %s\n%s", $expected_file, $diff;
}

