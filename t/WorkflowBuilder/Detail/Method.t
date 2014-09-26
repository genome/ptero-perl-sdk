use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::Detail::Method');

{
    my $hashref = {
        name => 'foo',
        submitUrl => 'http://example.com',
        parameters => {
            hashthing => {
                keya => 'meow',
                keyb => 'woof',
            },
            arraything => [
                'one', 2, 'octopus',
            ],
            scalarthing => 'corgis everywhere',
        }
    };

    my $method = Ptero::WorkflowBuilder::Detail::Method->from_hashref($hashref);

    is_deeply($method->to_hashref, $hashref, 'round trip hashref to method');
};


done_testing();

