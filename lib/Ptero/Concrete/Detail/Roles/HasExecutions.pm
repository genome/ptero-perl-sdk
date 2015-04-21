package Ptero::Concrete::Detail::Roles::HasExecutions;

use Moose::Role;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);

use Ptero::Concrete::Detail::Workflow::Execution;

has 'executions' => (
    is => 'rw',
    isa => 'HashRef[Ptero::Concrete::Detail::Workflow::Execution]',
);

requires "to_hashref";

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});

    my $hashref_executions = delete $hashref->{executions};
    my $self = $class->new(%$hashref);

    my %executions;
    while (my ($color, $execution_data) = each %$hashref_executions) {
        $executions{$color} = Ptero::Concrete::Detail::Workflow::Execution->from_hashref(
            $execution_data);
    }

    $self->executions(\%executions);

    return $self;
}

around "to_hashref", sub {
    my $orig = shift;
    my $self = shift;

    my $hashref = $self->$orig;

    $hashref->{executions} = {
        map {$_->color, $_->to_hashref} values %{$self->executions}};

    return $hashref;
};

1;
