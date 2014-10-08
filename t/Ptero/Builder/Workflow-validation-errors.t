use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::Builder::TestHelpers qw(
    build_nested_workflow
    build_basic_workflow
    create_basic_task
);

{
    my $workflow = build_basic_workflow('duplicate-task-name');
    create_basic_task($workflow, 'B');

    is_deeply([$workflow->validation_errors], [
            'Orphaned task(s) on Workflow (duplicate-task-name) named: "B"'
        ], 'orphaned task');

    $workflow->tasks->[1]->name('A');
    is_deeply([$workflow->validation_errors], [
            'Duplicate task names on Workflow (duplicate-task-name): "A"',
        ], 'duplicate task names');
}

{
    my $workflow = build_basic_workflow('missing-task-names');
    $workflow->connect_input(
        source_property => 'C_in',
        destination => 'C',
        destination_property => 'C_in',
    );

    is_deeply([$workflow->validation_errors], [
        'Links on Workflow (missing-task-names) refer to non-existing tasks: "C"'
        ], 'missing task names');
}

{
    my $workflow = build_nested_workflow('missing-manditory-input');

    is_deeply([$workflow->validation_errors], [], 'no validation errors (nested)');

    # create an additional manditory input
    my $task = $workflow->task_named('A');
    $task->methods->[0]->connect_input(
        source_property => 'A_in_two',
        destination => 'A',
        destination_property => 'A_in_two',
    );
    is_deeply([$workflow->validation_errors], [
            'No links on Workflow (missing-manditory-input) targeting mandatory input(s): ("A", "A_in_two")'
        ], 'missing manditory input');
}

{
    my $workflow = build_nested_workflow('invalid-output');

    my $inner_workflow = $workflow->task_named('A')->methods->[0];
    $inner_workflow->connect_output(
        source => 'A',
        source_property => 'A_out_two',
        destination_property => 'A_out_two',
    );
    is_deeply([$workflow->validation_errors], [], 'no validation errors (task has unknown io properties)');

    $workflow->connect_output(
        source => 'A',
        source_property => 'A_out_missing',
        destination_property => 'A_out_missing',
    );
    is_deeply([$workflow->validation_errors], [
            'Task "A" in Workflow (invalid-output) has no output named "A_out_missing"',
        ], 'invalid output');
}

{
    my $workflow = build_basic_workflow('multi-link-target');
    $workflow->connect_input(
        source_property => 'A_in_two',
        destination => 'A',
        destination_property => 'A_in',
    );
    is_deeply([$workflow->validation_errors], [
            qq(Multiple links on Workflow (multi-link-target) target the same input_property:\nPtero::Builder::Detail::Workflow::Link(source => "input connector", source_property => "A_in", destination => "A", destination_property => "A_in"),\nPtero::Builder::Detail::Workflow::Link(source => "input connector", source_property => "A_in_two", destination => "A", destination_property => "A_in")),
        ], 'multi link target');

}

{
    my $workflow = build_nested_workflow('cycle');
    create_basic_task($workflow, 'B');
    $workflow->link_tasks(
        source => 'A',
        source_property => 'A_out',
        destination => 'B',
        destination_property => 'B_in',
    );
    $workflow->link_tasks(
        source => 'B',
        source_property => 'B_out',
        destination => 'A',
        destination_property => 'A_in_from_B',
    );
    is_deeply([$workflow->validation_errors], [
            'A cycle exists in Workflow (cycle) involving the following tasks: ("A", "B")',
        ], 'cycle');
}

done_testing();
