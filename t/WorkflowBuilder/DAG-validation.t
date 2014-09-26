use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use WorkflowBuilder::TestHelper qw(
    create_simple_dag
    create_nested_dag
    create_command
);

use_ok('Ptero::WorkflowBuilder::DAG');

{
    my $dag = create_simple_dag('duplicate-nodes-dag');

    is_deeply([$dag->_node_name_errors], [],
        'no duplicate nodes error');

    $dag->add_node($dag->node_named('A'));

    is_deeply([$dag->_node_name_errors],
        ['Duplicate node names: "A"'],
        'duplicate nodes error');
}

{
    my $dag = create_simple_dag('orphaned-node-dag');

    is_deeply([$dag->_orphaned_node_errors], [],
        'no orphaned nodes error');

    $dag->add_node(Ptero::WorkflowBuilder::Command->new(
            name => 'C'));

    is_deeply([$dag->_orphaned_node_errors],
        ['Orphaned node names: "C"'],
        'orphaned nodes error');
}

{
    my $dag = create_simple_dag('orphaned-node-dag');

    is_deeply([$dag->_edge_target_errors], [],
        'no edge target error');

    $dag->create_edge(
        source => 'A', source_property => 'foo',
        destination => 'C', destination_property => 'bar');

    is_deeply([$dag->_edge_target_errors],
        ['Edges have invalid targets: "C"'],
        'edge target error');
}

{
    my $parent_dag = create_simple_dag('parent-dag');
    my $sub_dag = create_simple_dag('sub-dag');

    is_deeply([$parent_dag->_node_input_errors], [],
        'no mandatory inputs error');

    $parent_dag->add_node($sub_dag);

    is_deeply([$parent_dag->_node_input_errors],
        ['No edges targeting mandatory input(s): ("sub-dag", "in_a")'],
        'mandatory inputs error');

    $parent_dag->connect_input(
        source_property => 'sub_in_a',
        destination => $sub_dag,
        destination_property => 'in_a',
    );
    $parent_dag->connect_output(
        source => $sub_dag,
        source_property => 'out_a',
        destination_property => 'sub_out_a',
    );

    is_deeply([$parent_dag->_node_input_errors], [],
        'fixed mandatory inputs error');

    $sub_dag->parallel_by([['in_parallel']]);

    is_deeply([$parent_dag->_node_input_errors],
        ['No edges targeting mandatory input(s): ("sub-dag", "in_parallel")'],
        'mandatory inputs error for parallel_by');

    $parent_dag->connect_input(
        destination => 'sub-dag',
        destination_property => 'in_parallel',
        source_property => 'sub_in_parallel'
    );

    is_deeply([$parent_dag->_node_input_errors], [],
        'fixed mandatory inputs error for parallel_by');
}

{
    my $dag = create_nested_dag('outputs-exist-dag');

    is_deeply([$dag->_dag_output_errors], [],
        'no dag output error');

    $dag->connect_output(
        source => 'sub-dag',
        source_property => 'missing-property',
        destination_property => 'arbitrary'
    );

    is_deeply([$dag->_dag_output_errors],
        ['Node "sub-dag" has no output named "missing-property"'],
        'dag output error');
}

{
    my $dag = create_simple_dag('multiple-edges-target-dag');

    is_deeply([$dag->_multiple_edge_target_errors], [],
        'no multiple edges target error');

    $dag->add_edge($dag->edges->[0]);

    is_deeply([$dag->_multiple_edge_target_errors],
        ['Destination "A.in_a" is targeted by multiple edges from: ("input connector.in_a", "input connector.in_a")'],
        'multiple edge target error');
}

{
    my $dag = create_nested_dag('dag-with-cycle');

    is_deeply([$dag->_cycle_errors], [], 'no cycles found as expected');

    $dag->create_edge(
        source => 'sub-dag',
        destination => 'A',
        source_property => 'loop_to_a',
        destination_property => 'loop_to_a',
    );
    $dag->create_edge(
        source => 'A',
        destination => 'sub-dag',
        source_property => 'loop_from_a',
        destination_property => 'loop_from_a',
    );

    is_deeply([$dag->_cycle_errors],
        ['A cycle exists involving the following nodes: ("A", "sub-dag")'],
        'a cycle found as expected');
}

{
    my $dag = create_simple_dag('dag-with-isolated-cycle');

    for my $name (qw(B C D)) {
        $dag->add_node(create_command($name));
    }
    $dag->create_edge(
        source => 'B',
        destination => 'C',
        source_property => 'loop',
        destination_property => 'loop',
    );
    $dag->create_edge(
        source => 'C',
        destination => 'D',
        source_property => 'loop',
        destination_property => 'loop',
    );
    $dag->create_edge(
        source => 'D',
        destination => 'B',
        source_property => 'loop',
        destination_property => 'loop',
    );

    is_deeply([$dag->_cycle_errors],
        ['A cycle exists involving the following nodes: ("B", "C", "D")'],
        'an isolated cycle found as expected');
}

{
    my $dag = create_simple_dag('invalid-dag-dies');

    lives_ok {$dag->validate}
        'test dag validates without dying';

    $dag->add_node($dag->node_named('A'));

    dies_ok {$dag->validate}
        'test invalid dag dies on validate';
}

done_testing();
