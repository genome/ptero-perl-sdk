use strict;
use warnings FATAL => 'all';

use Test::Exception;
use Test::More;

use_ok('Ptero::WorkflowBuilder::Detail::Method');

{
    my $hashref = {
        name => 'foo',
        service => 'bar',
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
    is_deeply($method->to_hashref, $hashref, 'round trip hashref');

    $hashref->{constantParameters} = {
        another_hashthing => {
            keya => 'meow',
            keyb => 'woof',
        },
        another_arraything => [
            'one', 2, 'octopus',
        ],
        another_scalarthing => 'corgis everywhere',
    };

    $method = Ptero::WorkflowBuilder::Detail::Method->from_hashref($hashref);
    is_deeply($method->to_hashref, $hashref, 'round trip hashref with constantParameters');
};

{
    my $method = Ptero::WorkflowBuilder::Detail::Method->new(
        name => 'foo', service => 'bar',
        parameters => { a => 'b', c => 'd'},
        constant_parameters => { a => 'b', e =>'f' },
    );
    is_deeply([$method->validation_errors],
        ['Method (foo) has a key collision "a" between parameters and constant_parameters'],
        'key collision results in error');
};

subtest 'parameter_calculation_method' => sub{
    my $parent = create_method('parent');
    my $child = create_method('child');
    $parent->set_parameter_calculation_method($child);

    is($child->parent_method, $parent, 'parent relationship gets set up');
    is_deeply($child->lineage, Set::Scalar->new($child, $parent), 'lineage is set up');
    throws_ok sub {$child->set_parameter_calculation_method($parent)},
        qr/lineage/, 'cycle detection works';
    throws_ok sub {$parent->set_parameter_calculation_method($child)},
        qr/already calculating/, 'cannot add twice';

    my $expected_hashref = {
        %{method_hashref('parent')},
        parameterCalculationMethod => {
            %{method_hashref('child')},
        },
    };
    is_deeply($parent->to_hashref, $expected_hashref, 'to_hashref');

    my $from_hashref = Ptero::WorkflowBuilder::Detail::Method->from_hashref($expected_hashref);
    is_deeply($from_hashref->to_hashref, $expected_hashref, 'roundtrip');

    $parent->unset_parameter_calculation_method();
    delete $expected_hashref->{parameterCalculationMethod};
    is_deeply($parent->to_hashref, $expected_hashref, 'can remove');
};

sub method_hashref {
    my $name = shift;
    return {
        name => $name, service => 'bar', parameters => { a => 'b', },
    };
}

sub create_method {
    my $name = shift;

    return Ptero::WorkflowBuilder::Detail::Method->new(method_hashref($name));
}

done_testing();

