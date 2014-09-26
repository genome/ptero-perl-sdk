use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::WorkflowBuilder::Detail::Method;


use_ok('Ptero::WorkflowBuilder::Command');

my $method = {
    name => 'foo',
    submitUrl => 'http://example.com',
    parameters => {},
};

{
    my $command_hashref = {
        methods => [$method],
    };

    my $command = Ptero::WorkflowBuilder::Command->from_hashref(
        $command_hashref, 'squid');

    is_deeply($command->to_hashref, $command_hashref,
        'round trip hashref to command');
};

{
    my $command_hashref = {
    };

    throws_ok {Ptero::WorkflowBuilder::Command->from_hashref(
            $command_hashref, 'bad-methods-in-this-command')}
        qr/Command hashref must contain a methods arrayref/,
        'no methods in hashref';

    $command_hashref->{methods} = 'not-an-arrayref';

    throws_ok {Ptero::WorkflowBuilder::Command->from_hashref(
            $command_hashref, 'bad-methods-in-this-command')}
        qr/Command hashref must contain a methods arrayref/,
        'methods is not an arrayref';
};

{
    my $command_hashref = {
        methods => [],
    };

    my $command = Ptero::WorkflowBuilder::Command->from_hashref(
        $command_hashref, 'halibut');

    is_deeply([$command->_method_errors],
        ['Command named "halibut" must have at least one method'],
        'command must have at least one method');
};

{
    my $command_hashref = {
        methods => [$method],
    };

    my $command = Ptero::WorkflowBuilder::Command->from_hashref(
        $command_hashref, 'input connector');

    is_deeply([$command->_name_errors],
        ['Node may not be named "input connector"'],
        'command may not be named "input connector"');

    $command->name('output connector');

    is_deeply([$command->_name_errors],
        ['Node may not be named "output connector"'],
        'command may not be named "output conenctor"');
};

{
    my $command_hashref = {
        methods => [$method],
        parallelBy => 'qux',
    };

    my $command = Ptero::WorkflowBuilder::Command->from_hashref(
        $command_hashref, 'with-parallel-by');

    is_deeply([$command->input_properties], ['qux'],
        'parallel_by is in input_properties');
    is_deeply($command->to_hashref, $command_hashref,
        'command hashref roundtrip');
};

done_testing();
