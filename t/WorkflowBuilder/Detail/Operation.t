use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;
use Ptero::WorkflowBuilder::Detail::OperationMethod;


use_ok('Ptero::WorkflowBuilder::Detail::Operation');

{
    my $opmethod = Ptero::WorkflowBuilder::Detail::OperationMethod->from_hashref({
        name => 'foo',
        submit_url => 'http://example.com',
        parameters => {}
    });

    my $operation_hashref = {
        name => 'squid',
        methods => [$opmethod],
    };

    my $operation = Ptero::WorkflowBuilder::Detail::Operation->from_hashref($operation_hashref);

    is_deeply($operation->to_hashref, $operation_hashref, 'round trip hashref to operation');
};


{
    my $operation_hashref = {
        name => 'halibut',
        methods => [],
    };

    my $operation = Ptero::WorkflowBuilder::Detail::Operation->from_hashref($operation_hashref);

    throws_ok {$operation->validate}
        qr/Operation must have at least one method/, 'caught no methods okay';
};

done_testing();
