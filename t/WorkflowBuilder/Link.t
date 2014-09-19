use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::Detail::Link');

{
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(
        source => 'source node', source_property => 'output',
        destination => 'destination node', destination_property => 'input'
    );

    my $expected_hashref = {
        source => 'source node',
        destination => 'destination node',
        source_property => 'output',
        destination_property => 'input',
    };
    is_deeply($link->to_hashref, $expected_hashref, 'typical link produces expected hashref');
};

{
    my $expected_hashref = {
        source => 'source node',
        destination => 'destination node',
        source_property => 'output',
        destination_property => 'input',
    };
    my $link = Ptero::WorkflowBuilder::Detail::Link->from_hashref($expected_hashref);
    is_deeply($link->to_hashref, $expected_hashref, 'link roundtrip from/to_hashref');
};

{
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(
        source_property => 'output',
        destination => 'destination node', destination_property => 'input'
    );

    my $expected_hashref = {
        source => 'input connector',
        destination => 'destination node',
        source_property => 'output',
        destination_property => 'input',
    };
    is_deeply($link->to_hashref, $expected_hashref, 'missing source node uses input connector');
};

{
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(
        source => 'source node', source_property => 'output',
        destination_property => 'input'
    );

    my $expected_hashref = {
        source => 'source node',
        destination => 'output connector',
        source_property => 'output',
        destination_property => 'input',
    };
    is_deeply($link->to_hashref, $expected_hashref,
        'missing destination node uses output connector');
};

{
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(
        source => 'single-node', source_property => 'output',
        destination => 'single-node', destination_property => 'input',
    );

    is_deeply([$link->validation_errors],
        ['Source and destination nodes on link are both named "single-node"'],
        'source and destination nodes on link have same name');
};

done_testing();
