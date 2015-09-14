use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use_ok('Ptero::Builder::Job');

{
    my $sc = Ptero::Builder::Job->new(
        name => 'foo',
        service_url => 'http://example.com/v1',
        parameters => {
            commandLine => ['echo', 'hi'],
            user => 'testuser',
            workingDirectory => '/test/working/directory',
        },
    );

    is($sc->service, 'job',
        'service automatically set to job');
}

{
    my $sc = Ptero::Builder::Job->new(
        name => 'foo',
        service_url => 'http://example.com/v1',
        parameters => {
            commandLine => ['echo', 'hi'],
            user => 'testuser',
            workingDirectory => '/test/working/directory',
        },
    );

    is_deeply([$sc->validation_errors], [],
        'no validation errors for shell-command style parameters');

    delete $sc->parameters->{user};
    is_deeply([$sc->validation_errors],
        ['Method (foo) is missing one or more required parameter(s): "user"'],
        'missing required parameter errors');

    $sc->parameters->{bar} = 'baz';
    is_deeply([$sc->validation_errors],
        [
            'Method (foo) is missing one or more required parameter(s): "user"',
            'Method (foo) has one or more invalid parameter(s): "bar"',
        ],
        'invalid parameter errors');
}

{
    my $lsf = Ptero::Builder::Job->new(
        name => 'foo',
        service_url => 'http://example.com/v1',
        parameters => {
            command => ['echo', 'hi'],
            cwd => '/test/working/directory',
            environment => { FOO => 'bar' },
            options => {},
            rLimits => {},
            user => 'testuser',
        },
    );

    is_deeply([$lsf->validation_errors], [],
        'no validation errors for lsf-style parameters');
}

done_testing();
