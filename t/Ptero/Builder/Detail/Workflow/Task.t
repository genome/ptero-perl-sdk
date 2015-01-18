use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use_ok('Ptero::Builder::ShellCommand');
use_ok('Ptero::Builder::Detail::Workflow::Task');

{
    my $t = Ptero::Builder::Detail::Workflow::Task->new(
        name => 'foo',
        parallel_by => [['bar', 'baz'], ['qux']],
    );

    is_deeply([$t->parallel_by_properties], ['bar', 'baz', 'qux'],
        'parallel_by_properties');

    is_deeply([$t->parallel_by_properties], [sort $t->known_input_properties],
        'known_input_properties from parallel_by');
}

subtest VALIDATION_ERRORS => sub {
    my $sc = Ptero::Builder::ShellCommand->new(
        name => 'test-shell-command',
        parameters => {
            commandLine => ['echo', 'hi'],
            user => 'testuser',
            workingDirectory => '/test/working/directory',
        },
    );
    my $t = Ptero::Builder::Detail::Workflow::Task->new(
        name => 'test-task',
    );
    $t->add_method($sc);

    is_deeply([$t->validation_errors], [], 'no validation errors');

    $t->name('input connector');
    is_deeply([$t->validation_errors],
        [
            'Task may not be named "input connector"',
        ], 'name cannot be input connector');

    $t->name('output connector');
    is_deeply([$t->validation_errors],
        [
            'Task may not be named "output connector"',
        ], 'name cannot be output connector');

    $t->name('foo');
    $sc->parameters->{invalid_parameter} = 'bad';
    is_deeply([$t->validation_errors],
        [
            'Method (test-shell-command) has one or more invalid parameter(s): "invalid_parameter"',
        ], 'errors from methods');

    delete $t->methods->[0];
    is_deeply([$t->validation_errors],
        [
            'Task named "foo" must have at least one method',
        ], 'no methods');
};

done_testing();
