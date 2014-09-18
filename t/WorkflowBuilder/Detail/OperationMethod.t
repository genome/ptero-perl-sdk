use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;


use_ok('Ptero::WorkflowBuilder::Detail::OperationMethod');

{
    my $hashref = {
        name => 'foo',
        submit_url => 'http://example.com',
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

    my $opmethod = Ptero::WorkflowBuilder::Detail::OperationMethod->from_hashref($hashref);

    is_deeply($opmethod->to_hashref, $hashref, 'round trip hashref to operation method');
};


done_testing();

