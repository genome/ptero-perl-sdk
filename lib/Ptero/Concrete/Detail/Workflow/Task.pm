package Ptero::Concrete::Detail::Workflow::Task;

use Moose;
use warnings FATAL => 'all';

use Ptero::Concrete::DAG;
use Ptero::Concrete::ShellCommand;
use Ptero::Concrete::Detail::Workflow::Execution;
use Data::Dump qw(pp);

use Params::Validate qw(validate_pos :types);

use Ptero::Concrete::Detail::Workflow::Block;
use Ptero::Concrete::Detail::Workflow::Converge;

extends 'Ptero::Builder::Detail::Workflow::Task';
with 'Ptero::Concrete::Detail::Roles::CanWriteReport';

has 'executions' => (
    is => 'rw',
    isa => 'HashRef[Ptero::Concrete::Detail::Workflow::Execution]',
);

sub class_lookup {
    return {
        'shell-command' => 'Ptero::Concrete::ShellCommand',
        'workflow' => 'Ptero::Concrete::DAG',
        'workflow-block' => 'Ptero::Concrete::Detail::Workflow::Block',
        'workflow-converge' => 'Ptero::Concrete::Detail::Workflow::Converge',
    };
}

sub _write_report {
    my $self = shift;
    my ($handle, $indent, $color, $force) = $self->params_validator(@_);

    my $parallel_by_str = '';
    if ($self->has_parallel_by) {
        my $inputs = $self->executions->{$color}->inputs;
        $parallel_by_str = sprintf("parallel-by: %s", $self->parallel_by);
    }

    my $execution = $self->executions->{$color};
    if ($execution) {
        printf $handle $self->format_line,
            'Task',
            $execution->status,
            $execution->datetime_started,
            $execution->duration,
            join(', ', $execution->parallel_indexes),
            $self->indentation_str x $indent,
            $self->name . ' ' . $parallel_by_str;
    }

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
