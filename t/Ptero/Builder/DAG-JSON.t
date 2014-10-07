use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Slurp qw();
use Ptero::Builder::TestHelpers qw(
    build_nested_dag
);

my $test_dir = sprintf '%s.d', __FILE__;

use_ok('Ptero::Builder::DAG');

{
    my $dag = build_nested_dag('parent-dag');
    regenerate_test_data($dag, 'nested');

    is($dag->to_json(pretty => 1), get_test_json('nested'), 'nested to_json');
}

{
    my $blessed_json = get_test_json('nested');
    my $dag = Ptero::Builder::DAG->from_json($blessed_json, 'some-workflow');
    is($dag->to_json, $blessed_json, 'nested roundtrip');
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
    my $dag = shift;
    my $name = shift;
    my $json_filename = File::Spec->join($test_dir, $name . '.json');
    if ($ENV{REGENERATE_TEST_DATA}) {
        File::Slurp::write_file($json_filename, $dag->to_json(pretty => 1) . "\n");
    }
}
