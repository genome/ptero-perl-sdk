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
    is_deeply([$dag->input_properties], ['A_in'], 'input properties');
    is_deeply([$dag->output_properties], ['A_out'], 'output properties');

    is_deeply($dag->task_named('A')->methods->[0]->parameters->{commandLine},
        ['echo', 'basic-dag'], 'task named');
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

    is_deeply([$dag->input_properties], ['A_in', 'B_in'], 'new input properties');
    is_deeply([$dag->output_properties], ['A_out'], 'new output properties');
}

done_testing();