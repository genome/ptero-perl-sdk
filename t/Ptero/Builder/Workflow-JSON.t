use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Slurp qw();
use Ptero::Builder::TestHelpers qw(
    build_nested_workflow
);

my $test_dir = sprintf '%s.d', __FILE__;

use_ok('Ptero::Builder::Workflow');

{
    my $workflow = build_nested_workflow('parent-workflow');
    regenerate_test_data($workflow, 'nested');

    is($workflow->to_json(pretty => 1), get_test_json('nested'), 'nested to_json');
}

{
    my $blessed_json = get_test_json('nested');
    my $workflow = Ptero::Builder::Workflow->from_json($blessed_json, 'some-workflow');
    is($workflow->to_json, $blessed_json, 'nested roundtrip');
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
        File::Slurp::write_file($json_filename, $workflow->to_json(pretty => 1) . "\n");
    }
}
