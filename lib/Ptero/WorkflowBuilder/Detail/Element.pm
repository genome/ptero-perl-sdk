package Ptero::WorkflowBuilder::Detail::Element;
use Moose::Role;
use warnings FATAL => 'all';

requires 'to_hashref';

sub from_hashref {
    my ($class, $hashref) = @_;

    return $class->new(%$hashref);
}

1;
