package Ptero::Concrete::Detail::Workflow::Task;

use Moose;
use warnings FATAL => 'all';

use Ptero::Concrete::Workflow;
use Ptero::Concrete::ShellCommand;
use Ptero::Concrete::Detail::Workflow::Execution;

use Params::Validate qw(validate_pos :types);

extends 'Ptero::Builder::Detail::Workflow::Task';

has 'executions' => (
    is => 'rw',
    isa => 'HashRef[Ptero::Concrete::Detail::Workflow::Execution]',
);

sub class_lookup {
    return {
        'shell-command' => 'Ptero::Concrete::ShellCommand',
        'workflow' => 'Ptero::Concrete::Workflow',
    };
}

sub from_hashref {
    my ($class, $hashref, $name) = validate_pos(@_, 1, {type => HASHREF}, {type => SCALAR});
    my $self = $class->SUPER::from_hashref($hashref, $name);

    my %executions;
    while (my ($color, $execution_hashref) = each %{$hashref->{executions}}) {
        $executions{$color} = Ptero::Concrete::Detail::Workflow::Execution->from_hashref(
            $execution_hashref);
    }

    $self->executions(\%executions);

    return $self;
}

sub to_hashref {
    my $self = shift;
    my $hashref = $self->SUPER::to_hashref;
    $hashref->{executions} = {
        map {$_->color, $_->to_hashref} values %{$self->executions}};

    return $hashref;
}

__PACKAGE__->meta->make_immutable;

__END__
