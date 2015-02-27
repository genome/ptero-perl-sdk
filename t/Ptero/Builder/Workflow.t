use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use File::Basename qw(dirname);
use lib dirname(dirname(dirname(__FILE__)));
use Ptero::Builder::TestHelpers qw(
    build_basic_workflow
    create_basic_task
);

use_ok('Ptero::Builder::Workflow');
use_ok('Ptero::Builder::ShellCommand');

{
    my $workflow = build_basic_workflow('basic');
    is_deeply([$workflow->known_input_properties], ['A_in'], 'known input properties');
    ok($workflow->has_possible_output_property('A_out'), 'A_out is an output');
    ok(!$workflow->has_possible_output_property('foo'), 'foo is not an output');

    is_deeply($workflow->task_named('A')->methods->[0]->parameters->{commandLine},
        ['echo', 'basic-workflow'], 'task named');
    throws_ok {$workflow->task_named('input connector')}
        qr/no task named/, 'no task named input connector';
}

{
    my $workflow = build_basic_workflow('basic');
    create_basic_task($workflow, 'B');
    $workflow->connect_input(
        source_property => 'B_in',
        destination => 'B',
        destination_property => 'B_in',
    );
    $workflow->link_tasks(
        source => 'B',
        source_property => 'B_out',
        destination => 'A',
        destination_property => 'A_to_B',
    );

    is_deeply([$workflow->known_input_properties], ['A_in', 'B_in'], 'new known input properties');
}

done_testing();
