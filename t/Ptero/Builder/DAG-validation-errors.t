use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::Builder::TestHelpers qw(
    build_basic_task
    build_basic_dag
);

{
    my $dag = build_basic_dag('duplicate-task-name');
    $dag->add_task(build_basic_task('B'));

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

done_testing();
