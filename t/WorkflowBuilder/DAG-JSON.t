use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Slurp qw();
use WorkflowBuilder::TestHelper qw(
    create_simple_dag
    create_nested_dag
);

my $test_dir = sprintf '%s.d', __FILE__;

use_ok('Ptero::WorkflowBuilder::DAG');

sub get_test_json {
    my $json_filename = File::Spec->join($test_dir, 'blessed-dag.json');
    my $blessed_json = File::Slurp::read_file($json_filename);
    chomp($blessed_json);

    return $blessed_json;
}

sub regenerate_test_data {
    my $dag = shift;
    my $json_filename = File::Spec->join($test_dir, 'blessed-dag.json');
    if ($ENV{REGENERATE_TEST_DATA}) {
        File::Slurp::write_file($json_filename, $dag->to_json(pretty => 1) . "\n");
    }
}

{
    my $dag = create_nested_dag('parent-dag');
    regenerate_test_data($dag);

    is($dag->to_json(pretty => 1), get_test_json(), 'encode_as_json');
}

{
    my $blessed_json = get_test_json();
    my $dag = Ptero::WorkflowBuilder::DAG->from_json($blessed_json, 'some-workflow');
    is($dag->to_json, $blessed_json, 'json roundtrip');
}

done_testing();
