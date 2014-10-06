use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use_ok('Ptero::Builder::Detail::Link');

{
    my $link = Ptero::Builder::Detail::Link->new(
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

done_testing();
