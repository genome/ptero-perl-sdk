use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::Operation');
use_ok('Ptero::WorkflowBuilder::Detail::Link');

{
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(
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
    my $link = Ptero::WorkflowBuilder::Detail::Link->from_hashref($expected_hashref);
    is_deeply($link->to_hashref, $expected_hashref, 'link roundtrip from/to_hashref');
};

{
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(
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
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(
        source => 'source op', source_property => 'output',
        destination_property => 'input'
    );

    my $expected_hashref = {
        source => 'source op',
        destination => 'output connector',
        source_property => 'output',
        destination_property => 'input',
    };
    is_deeply($link->to_hashref, $expected_hashref,
        'missing destination operation uses output connector');
};

{
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(
        source => 'single-op', source_property => 'output',
        destination => 'single-op', destination_property => 'input',
    );

    is_deeply([$link->validation_errors],
        ['Source and destination operations on link are both named "single-op"'],
        'source and destination operations on link have same name');
};

done_testing();
