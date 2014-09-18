use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::Detail::Operation');
use_ok('Ptero::WorkflowBuilder::Link');

{
    my $link = Ptero::WorkflowBuilder::Link->new(
        source => 'source op', source_property => 'output',
        destination => 'destination op', destination_property => 'input'
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
    my $expected_hashref = {
        source => 'source op',
        destination => 'destination op',
        source_property => 'output',
        destination_property => 'input',
    };
    my $link = Ptero::WorkflowBuilder::Link->from_hashref($expected_hashref);
    is_deeply($link->to_hashref, $expected_hashref, 'link roundtrip from/to_hashref');
};

{
    my $link = Ptero::WorkflowBuilder::Link->new(
        source_property => 'output',
        destination => 'destination op', destination_property => 'input'
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
    my $link = Ptero::WorkflowBuilder::Link->new(
        source => 'source op', source_property => 'output',
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
    my $link = Ptero::WorkflowBuilder::Link->new(
        source => 'single-op', source_property => 'output',
        destination => 'single-op', destination_property => 'input',
    );

    throws_ok {$link->validate}
        qr/Source and destination operations cannot be the same \(single-op\)/,
        'caught source and destination op cannot be equal';
};

done_testing();
