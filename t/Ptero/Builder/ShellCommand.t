use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use_ok('Ptero::Builder::ShellCommand');

{
    my $sc = Ptero::Builder::ShellCommand->new(
        name => 'foo',
        parameters => {
            commandLine => ['echo', 'hi'],
            user => 'testuser',
            workingDirectory => '/test/working/directory',
        },
    );

    is($sc->service, 'shell-command',
        'service automatically set to shell-command');
}

{
    my $sc = Ptero::Builder::ShellCommand->new(
        name => 'foo',
        parameters => {
            commandLine => ['echo', 'hi'],
            user => 'testuser',
            workingDirectory => '/test/working/directory',
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
}

done_testing();
