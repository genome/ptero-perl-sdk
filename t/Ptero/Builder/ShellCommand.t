use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use_ok('Ptero::Builder::ShellCommand');

{
    my $sc = Ptero::Builder::ShellCommand->new(
        name => 'foo',
        parameters => { commandLine => ['echo', 'hi']},
    );

    is($sc->service, 'ShellCommand',
        'service automatically set to ShellCommand');
    is($sc->has_unknown_io_properties, 1,
        'has unknown io properties');
}

subtest VALIDATION_ERRORS => sub {
    my $sc = Ptero::Builder::ShellCommand->new(
        name => 'foo',
        parameters => {
            commandLine => ['echo', 'hi'],
            user => 'bob',
        },
    );

    is_deeply([$sc->validation_errors], [], 'no validation errors');

    delete $sc->parameters->{commandLine};
    is_deeply([$sc->validation_errors],
        ['Method (foo) is missing one or more required parameter(s): "commandLine"'],
        'missing required parameter errors');

    $sc->parameters->{bar} = 'baz';
    is_deeply([$sc->validation_errors],
        [
            'Method (foo) is missing one or more required parameter(s): "commandLine"',
            'Method (foo) has one or more invalid parameter(s): "bar"',
        ],
        'invalid parameter errors');
};

done_testing();
