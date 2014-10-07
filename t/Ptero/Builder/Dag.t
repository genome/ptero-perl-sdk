use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::Builder::TestHelpers qw(
    build_basic_task
    build_basic_dag
);

use_ok('Ptero::Builder::DAG');
use_ok('Ptero::Builder::ShellCommand');

{
    my $dag = build_basic_dag('basic');
    is_deeply([$dag->known_input_properties], ['A_in'], 'known input properties');
    ok($dag->has_possible_output_property('A_out'), 'A_out is an output');
    ok(!$dag->has_possible_output_property('foo'), 'foo is not an output');

    is_deeply($dag->task_named('A')->methods->[0]->parameters->{commandLine},
        ['echo', 'basic-dag'], 'task named');
    throws_ok {$dag->task_named('input connector')}
        qr/no task named/, 'no task named input connector';
}

{
    my $dag = build_basic_dag('basic');
    $dag->add_task(build_basic_task('B'));
    $dag->connect_input(
        source_property => 'B_in',
        destination => 'B',
        destination_property => 'B_in',
    );
    $dag->link_tasks(
        source => 'B',
        source_property => 'B_out',
        destination => 'A',
        destination_property => 'A_to_B',
    );

    is_deeply([$dag->known_input_properties], ['A_in', 'B_in'], 'new known input properties');
}

done_testing();
