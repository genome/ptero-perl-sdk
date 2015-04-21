use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Slurp qw();
use JSON qw(from_json);

my $test_dir = sprintf '%s.d', __FILE__;

use_ok('Ptero::Concrete::Workflow');

test_json_roundtrip('simple');
test_json_roundtrip('parallel');
test_json_roundtrip('converge');
test_json_roundtrip('block');


done_testing();

sub test_json_roundtrip {
    my $name = shift;
    my $blessed_json = get_test_json($name);
    my $workflow = Ptero::Concrete::Workflow->from_json(
        $blessed_json, 'some-workflow');
    isa_ok($workflow, 'Ptero::Concrete::Workflow');

    is_deeply(from_json($workflow->to_json),
        from_json($blessed_json), "$name roundtrip");
}

sub get_test_json {
    my $name = shift;
    my $json_filename = File::Spec->join($test_dir, $name . '.json');
    my $blessed_json = File::Slurp::read_file($json_filename);
    chomp($blessed_json);

    return $blessed_json;
}
