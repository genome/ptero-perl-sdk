use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::DAG');

my $operation_methods = [
    {
        name => 'shortcut',
        submitUrl => 'http://ptero-fork/v1/jobs',
        parameters => { },
    },
    {
        name => 'execute',
        submitUrl => 'http://ptero-lsf/v1/jobs',
        parameters => { },
    },
];

my $operations = {
    A => {
        methods => $operation_methods,
    },
    B => {
        methods => $operation_methods,
    },
};

my $edges = [
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
        nodes => $operations,
        edges => $edges,
    };
    return Ptero::WorkflowBuilder::DAG->from_hashref($hashref, $name);
}

{
    my $dag = create_test_dag('duplicate-nodes-dag');

    is_deeply([$dag->_validate_node_names_are_unique], [],
        'no duplicate nodes error');

    $dag->add_node($dag->node_named('A'));

    is_deeply([$dag->_validate_node_names_are_unique],
        ['Duplicate node names: "A"'],
        'duplicate nodes error');
}

{
    my $dag = create_test_dag('orphaned-node-dag');

    is_deeply([$dag->_validate_edge_node_consistency], [],
        'no orphaned nodes error');

    $dag->add_node(Ptero::WorkflowBuilder::Operation->new(
            name => 'C'));

    is_deeply([$dag->_validate_edge_node_consistency],
        ['Orphaned node names: "C"'],
        'orphaned nodes error');
}

{
    my $dag = create_test_dag('orphaned-node-dag');

    is_deeply([$dag->_validate_edge_node_consistency], [],
        'no invalid edge target error');

    $dag->create_edge(
        source => 'A', source_property => 'foo',
        destination => 'C', destination_property => 'bar');

    is_deeply([$dag->_validate_edge_node_consistency],
        ['Edges have invalid targets: "C"'],
        'invalid edge target error');
}

{
    my $sub_dag = create_test_dag('mandatory-inputs-sub-dag');

    my $super_dag = create_test_dag('mandatory-inputs-super-dag');

    is_deeply([$super_dag->_validate_mandatory_inputs], [],
        'no mandatory inputs error');

    $super_dag->add_node($sub_dag);

    is_deeply([$super_dag->_validate_mandatory_inputs],
        ['No edges targeting mandatory input(s): ("mandatory-inputs-sub-dag", "in_a"), ("mandatory-inputs-sub-dag", "in_b")'],
        'mandatory inputs error');

    $super_dag->connect_input(
        destination => 'mandatory-inputs-sub-dag',
        destination_property => 'in_a',
        source_property => 'sub_in_a'
    );

    $super_dag->connect_input(
        destination => 'mandatory-inputs-sub-dag',
        destination_property => 'in_b',
        source_property => 'sub_in_b'
    );

    is_deeply([$super_dag->_validate_mandatory_inputs], [],
        'fixed mandatory inputs error');

    $sub_dag->parallel_by('in_parallel');

    is_deeply([$super_dag->_validate_mandatory_inputs],
        ['No edges targeting mandatory input(s): ("mandatory-inputs-sub-dag", "in_parallel")'],
        'mandatory inputs error for parallel_by');

    $super_dag->connect_input(
        destination => 'mandatory-inputs-sub-dag',
        destination_property => 'in_parallel',
        source_property => 'sub_in_parallel'
    );

    is_deeply([$super_dag->_validate_mandatory_inputs], [],
        'fixed mandatory inputs error for parallel_by');
}

{
    my $sub_dag = create_test_dag('outputs-exist-sub-dag');
    my $super_dag = create_test_dag('outputs-exist-super-dag');
    $super_dag->add_node($sub_dag);

    is_deeply([$super_dag->_validate_outputs_exist], [],
        'no validate outputs error');

    $super_dag->connect_output(
        source => 'outputs-exist-sub-dag',
        source_property => 'missing-property',
        destination_property => 'arbitrary'
    );

    is_deeply([$super_dag->_validate_outputs_exist],
        ['Node "outputs-exist-sub-dag" has no output named "missing-property"'],
        'validate outputs error');
}

{
    my $dag = create_test_dag('multiple-edges-target-dag');

    is_deeply([$dag->_validate_edge_targets_are_unique], [],
        'no multiple edges target error');

    $dag->add_edge($dag->edges->[0]);

    is_deeply([$dag->_validate_edge_targets_are_unique],
        ['Destination "A.param" is targeted by multiple edges from: ("input connector.in_a", "input connector.in_a")'],
        'invalid edge target error');
}

{
    my $dag = create_test_dag('duplicate-nodes-dag');

    lives_ok {$dag->validate}
        'test dag validates without dying';

    $dag->add_node($dag->node_named('A'));

    dies_ok {$dag->validate}
        'test dag with duplicate nodes dies on validate';
}

done_testing();
