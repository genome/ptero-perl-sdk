use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::Builder::TestHelpers qw(
    build_nested_dag
    build_basic_dag
    create_basic_task
);

{
    my $dag = build_basic_dag('duplicate-task-name');
    create_basic_task($dag, 'B');

    is_deeply([$dag->validation_errors], [
            'Orphaned task(s) on DAG (duplicate-task-name) named: "B"'
        ], 'orphaned task');

    $dag->tasks->[1]->name('A');
    is_deeply([$dag->validation_errors], [
            'Duplicate task names on DAG (duplicate-task-name): "A"',
        ], 'duplicate task names');
}

{
    my $dag = build_basic_dag('missing-task-names');
    $dag->connect_input(
        source_property => 'C_in',
        destination => 'C',
        destination_property => 'C_in',
    );

    is_deeply([$dag->validation_errors], [
        'Links on DAG (missing-task-names) refer to non-existing tasks: "C"'
        ], 'missing task names');
}

{
    my $dag = build_nested_dag('missing-manditory-input');

    is_deeply([$dag->validation_errors], [], 'no validation errors (nested)');

    # create an additional manditory input
    my $task = $dag->task_named('A');
    $task->methods->[0]->connect_input(
        source_property => 'A_in_two',
        destination => 'A',
        destination_property => 'A_in_two',
    );
    is_deeply([$dag->validation_errors], [
            'No links on DAG (missing-manditory-input) targeting mandatory input(s): ("A", "A_in_two")'
        ], 'missing manditory input');
}

{
    my $dag = build_nested_dag('invalid-output');

    my $inner_dag = $dag->task_named('A')->methods->[0];
    $inner_dag->connect_output(
        source => 'A',
        source_property => 'A_out_two',
        destination_property => 'A_out_two',
    );
    is_deeply([$dag->validation_errors], [], 'no validation errors (task has unknown io properties)');

    $dag->connect_output(
        source => 'A',
        source_property => 'A_out_missing',
        destination_property => 'A_out_missing',
    );
    is_deeply([$dag->validation_errors], [
            'Task "A" in DAG (invalid-output) has no output named "A_out_missing"',
        ], 'invalid output');
}

{
    my $dag = build_basic_dag('multi-link-target');
    $dag->connect_input(
        source_property => 'A_in_two',
        destination => 'A',
        destination_property => 'A_in',
    );
    is_deeply([$dag->validation_errors], [
            qq(Multiple links on DAG (multi-link-target) target the same input_property:\nPtero::Builder::Detail::Link(source => "input connector", source_property => "A_in", destination => "A", destination_property => "A_in"),\nPtero::Builder::Detail::Link(source => "input connector", source_property => "A_in_two", destination => "A", destination_property => "A_in")),
        ], 'multi link target');

}

{
    my $dag = build_nested_dag('cycle');
    create_basic_task($dag, 'B');
    $dag->link_tasks(
        source => 'A',
        source_property => 'A_out',
        destination => 'B',
        destination_property => 'B_in',
    );
    $dag->link_tasks(
        source => 'B',
        source_property => 'B_out',
        destination => 'A',
        destination_property => 'A_in_from_B',
    );
    is_deeply([$dag->validation_errors], [
            'A cycle exists in DAG (cycle) involving the following tasks: ("A", "B")',
        ], 'cycle');
}

done_testing();
