package Ptero::Concrete::Detail::Workflow::Task;

use Moose;
use warnings FATAL => 'all';

use Ptero::Concrete::Workflow;
use Ptero::Concrete::ShellCommand;
use Ptero::Concrete::Detail::Workflow::Execution;
use Data::Dump qw(pp);

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

sub _write_report {
    my $self = shift;
    my ($handle, $indent, $color) = validate_pos(@_, 1, 1, 1);

    my $parallel_by_str = '';
    if ($self->has_parallel_by) {
        my $inputs = $self->executions->{$color}->inputs;
        $parallel_by_str = sprintf("parallel-by: %s", $self->parallel_by);
    }

    my $execution = $self->executions->{$color};
    printf $handle "%15s %10s %20s %13s %5s  %s%s\n",
        'Task',
        $execution->status,
        $execution->datetime_started,
        $execution->duration,
        $color,
        '. 'x$indent,
        $self->name . ' ' . $parallel_by_str;

    for my $method (@{$self->methods}) {
        $method->_write_report($handle, $indent+1, $color);
    }

    for my $child_execution ($self->executions_with_parent_color($color)) {
        for my $method (@{$self->methods}) {
            $method->_write_report($handle, $indent+1, $child_execution->color);
        }
    }
}

sub executions_with_parent_color {
    my ($self, $parent_color) = @_;

    my @result;
    for my $color (sort keys %{$self->executions}) {
        my $execution = $self->executions->{$color};
        if (defined $execution->parent_color && $execution->parent_color == $parent_color) {
            push @result, $execution;
        }
    }
    return @result;
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
