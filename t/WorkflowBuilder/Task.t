use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::WorkflowBuilder::Detail::Method;


use_ok('Ptero::WorkflowBuilder::Task');

my $method = {
    name => 'foo',
    submitUrl => 'http://example.com',
    parameters => {},
};

{
    my $task_hashref = {
        methods => [$method],
    };

    my $task = Ptero::WorkflowBuilder::Task->from_hashref(
        $task_hashref, 'squid');

    is_deeply($task->to_hashref, $task_hashref,
        'round trip hashref to task');
};

{
    my $task_hashref = {
    };

    throws_ok {Ptero::WorkflowBuilder::Task->from_hashref(
            $task_hashref, 'bad-methods-in-this-task')}
        qr/Task hashref must contain a methods arrayref/,
        'no methods in hashref';

    $task_hashref->{methods} = 'not-an-arrayref';

    throws_ok {Ptero::WorkflowBuilder::Task->from_hashref(
            $task_hashref, 'bad-methods-in-this-task')}
        qr/Task hashref must contain a methods arrayref/,
        'methods is not an arrayref';
};

{
    my $task_hashref = {
        methods => [],
    };

    my $task = Ptero::WorkflowBuilder::Task->from_hashref(
        $task_hashref, 'halibut');

    is_deeply([$task->_method_errors],
        ['Task named "halibut" must have at least one method'],
        'task must have at least one method');
};

{
    my $task_hashref = {
        methods => [$method],
    };

    my $task = Ptero::WorkflowBuilder::Task->from_hashref(
        $task_hashref, 'input connector');

    is_deeply([$task->_name_errors],
        ['Node may not be named "input connector"'],
        'task may not be named "input connector"');

    $task->name('output connector');

    is_deeply([$task->_name_errors],
        ['Node may not be named "output connector"'],
        'task may not be named "output conenctor"');
};

{
    my $task_hashref = {
        methods => [$method],
        parallelBy => [['qux']],
    };

    my $task = Ptero::WorkflowBuilder::Task->from_hashref(
        $task_hashref, 'with-parallel-by');

    is_deeply([$task->input_properties], ['qux'],
        'parallel_by is in input_properties');
    is_deeply($task->to_hashref, $task_hashref,
        'task hashref roundtrip');
};

done_testing();
