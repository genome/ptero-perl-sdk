use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::DAG');

my $operation_methods = [
    {
        name => 'shortcut',
        submit_url => 'http://ptero-fork/v1/jobs',
        parameters => { },
    },
    {
        name => 'execute',
        submit_url => 'http://ptero-lsf/v1/jobs',
        parameters => { },
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

sub create_test_dag {
    my $name = shift;
    my $hashref = {
        name => $name,
        operations => $operations,
        links => $links,
    };
    return Ptero::WorkflowBuilder::DAG->from_hashref($hashref);
}

{
    my $dag = create_test_dag('duplicate-operations-dag');

    is_deeply([$dag->_validate_operation_names_are_unique], [],
        'no duplicate operations error');

    $dag->add_operation($dag->operation_named('A'));

    is_deeply([$dag->_validate_operation_names_are_unique],
        ['Duplicate operation names: A'],
        'duplicate operations error');
}

done_testing();
