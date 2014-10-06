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

    is_deeply([$dag->validation_errors], [], 'no validation errors');

    $dag->tasks->[1]->name('A');
    is_deeply([$dag->validation_errors], [
            'Duplicate task names on DAG (duplicate-task-name): "A"',
        ], 'duplicate task names');
}

done_testing();
