use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::Detail::Operation');
use_ok('Ptero::WorkflowBuilder::Link');

{
    my $source_op = Ptero::WorkflowBuilder::Detail::Operation->new(
        name => 'source op',
    );
    my $destination_op = Ptero::WorkflowBuilder::Detail::Operation->new(
        name => 'destination op',
    );

    my $link = Ptero::WorkflowBuilder::Link->new(
        source => $source_op, source_property => 'output',
        destination => $destination_op, destination_property => 'input'
    );

    my $expected_hashref = {
        source => 'source op',
        destination => 'destination op',
        source_property => 'output',
        destination_property => 'input',
    };
    is_deeply($link->to_hashref, $expected_hashref, 'typical link produces expected hashref');
};

{
    my $destination_op = Ptero::WorkflowBuilder::Detail::Operation->new(
        name => 'destination op',
    );

    my $link = Ptero::WorkflowBuilder::Link->new(
        source_property => 'output',
        destination => $destination_op, destination_property => 'input'
    );

    my $expected_hashref = {
        source => 'input connector',
        destination => 'destination op',
        source_property => 'output',
        destination_property => 'input',
    };
    is_deeply($link->to_hashref, $expected_hashref, 'missing source operation uses input connector');
};

{
    my $source_op = Ptero::WorkflowBuilder::Detail::Operation->new(
        name => 'source op',
    );

    my $link = Ptero::WorkflowBuilder::Link->new(
        source => $source_op, source_property => 'output',
        destination_property => 'input'
    );

    my $expected_hashref = {
        source => 'source op',
        destination => 'output connector',
        source_property => 'output',
        destination_property => 'input',
    };
    is_deeply($link->to_hashref, $expected_hashref, 'missing destination operation uses output connector');
};

{
    my $op_name = 'single-op';

    my $op = Ptero::WorkflowBuilder::Detail::Operation->new(
        name => $op_name,
    );

    my $link = Ptero::WorkflowBuilder::Link->new(
        source => $op, source_property => 'output',
        destination => $op, destination_property => 'input',
    );

    throws_ok {$link->validate}
        qr/\QSource and destination operations cannot be the same ($op_name)\E/,
        'caught source and destination op cannot be equal';
};

done_testing();
