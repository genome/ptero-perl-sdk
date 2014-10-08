use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use_ok('Ptero::Builder::Detail::Workflow::Link');

{
    my $link = Ptero::Builder::Detail::Workflow::Link->new(
        source => 'foo',
        destination => 'bar',
        source_property => 'baz',
        destination_property => 'qux',
    );

    is_deeply([$link->validation_errors], [], 'no validation errors');

    $link->destination('foo');
    is_deeply([$link->validation_errors],
        ['Source and destination tasks on link are both named "foo"'],
        'source is destination');
}

{
    my $link = Ptero::Builder::Detail::Workflow::Link->new(
        source => 'output connector',
        destination => 'input connector',
        source_property => 'baz',
        destination_property => 'qux',
    );

    is_deeply([$link->validation_errors], [
            'Source cannot be named named "output connector"',
            'Destination cannot be named named "input connector"',
        ],
        'source and destination name errors');
}

done_testing();
