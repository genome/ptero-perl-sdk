use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use File::Slurp qw();


my $test_dir = sprintf '%s.d', __FILE__;

use_ok('Ptero::WorkflowBuilder::DAG');

my $operation_methods = [
    {
        name => 'shortcut',
        submit_url => 'http://ptero-fork/v1/jobs',
        parameters => {
            commandLine => ['genome-ptero-wrapper',
                'command', 'shortcut', 'NullCommand']
        },
    },
    {
        name => 'execute',
        submit_url => 'http://ptero-lsf/v1/jobs',
        parameters => {
            commandLine => ['genome-ptero-wrapper',
                'command', 'execute', 'NullCommand'],
            limit => {
                virtual_memory => 204800,
            },
            request => {
                min_cores => 4,
                memory => 200,
                temp_space => 5,
            },
            reserve => {
                min_cores => 4,
                memory => 200,
                temp_space => 5,
            },
        },
    },
];

my $operations = [
    {
        name => 'A',
        methods => $operation_methods,
    },
    {
        name => 'B',
        methods => $operation_methods,
    },
];

my $links = [
    {
        source => 'input connector',
        destination => 'A',
        source_property => 'in_a',
        destination_property => 'param',
    },
    {
        source => 'input connector',
        destination => 'B',
        source_property => 'in_b',
        destination_property => 'param',
    },
    {
        source => 'A',
        destination => 'output connector',
        source_property => 'out_a',
        destination_property => 'out_a',
    },
    {
        source => 'B',
        destination => 'output connector',
        source_property => 'out_a',
        destination_property => 'out_b',
    },
    {
        source => 'A',
        destination => 'B',
        source_property => 'out_a',
        destination_property => 'a_to_b',
    },
];

{
    my $hashref = {
        name => 'some-workflow',
        nodes => $operations,
        links => $links,
    };

    my $dag = Ptero::WorkflowBuilder::DAG->from_hashref($hashref);

    my $blessed_json = File::Slurp::read_file(
        File::Spec->join($test_dir, 'blessed-dag.json')
    );

    is($dag->encode_as_json, $blessed_json, 'encode_as_json')
}

done_testing();
