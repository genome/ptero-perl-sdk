package Ptero::Concrete::Workflow;

use Moose;
use warnings FATAL => 'all';

use Params::Validate qw(validate_pos :types);
use JSON qw();
use Graph::Directed qw();

use Ptero::Concrete::Detail::Workflow::Execution;
use Ptero::Concrete::Detail::Workflow::Task;
use Data::Dump qw(pp);

extends 'Ptero::Builder::Workflow';
with 'Ptero::Concrete::Detail::Roles::CanWriteReport';

my $codec = JSON->new()->canonical([1]);

has 'executions' => (
    is => 'rw',
    isa => 'HashRef[Ptero::Concrete::Detail::Workflow::Execution]',
);

has 'status' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

sub write_report {
    my $self = shift;
    my %p = Params::Validate::validate(@_, {
        handle => 1,
        indent => {default => 0},
    });
    my $handle = $p{handle};

    $self->_write_report($p{handle}, $p{indent}, 0, 1);
}

sub _write_report {
    my $self = shift;
    my ($handle, $indent, $color, $force) = $self->params_validator(@_);
    return unless exists $self->executions->{$color} or $force;

    if ($force) {
        printf $handle $self->format_line,
            'DAG',
            $self->status || '',
            '',
            '',
            '',
            $self->indentation_str x $indent,
            $self->name;
    } else {
        my $execution = $self->executions->{$color};
        printf $handle $self->format_line,
            'DAG',
            $execution->status,
            $execution->datetime_started,
            $execution->duration,
            join(', ', $execution->parallel_indexes),
            $self->indentation_str x $indent,
            $self->name;
    }

    for my $name ($self->sorted_tasks) {
        my $task = $self->task_named($name);
        $task->_write_report($handle, $indent+1, $color);
    }
}

# This implements a simple, but deterministic topological sorting of the tasks,
# excluding the 'input connector' and the 'output connector'.
sub sorted_tasks {
    my $self = shift;

    my $g = Graph::Directed->new();
    for my $link (@{$self->links}) {
        $g->add_edge($link->source, $link->destination);
    }

    my @result;
    my @task_names = sort $g->successors('input connector');
    my $task_set = Set::Scalar->new(@task_names);
    $g->delete_vertex('input connector');
    while (scalar(@task_names) > 0) {
        my $count = 0;
        for my $name (@task_names) {
            if ($g->in_degree($name) == 0) {
                unless ($name eq 'output connector') {
                    push @result, $name;
                }
                splice(@task_names, $count, 1);

                my @new_successors = grep {!$task_set->contains($_)} $g->successors($name);
                push @task_names, sort @new_successors;
                $task_set->insert(@new_successors);

                $g->delete_vertex($name);
                last;
            }
            $count++;
        }
    }

    return @result;
}

sub task_class { 'Ptero::Concrete::Detail::Workflow::Task' }

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});
    my $self = $class->SUPER::from_hashref($hashref);

    my %executions;
    while (my ($color, $execution_hashref) = each %{$hashref->{executions}}) {
        $executions{$color} = Ptero::Concrete::Detail::Workflow::Execution->from_hashref(
            $execution_hashref);
    }

    $self->executions(\%executions);
    $self->status($hashref->{status});

    return $self;
}

sub to_hashref {
    my $self = shift;
    my $hashref = $self->SUPER::to_hashref;
    $hashref->{executions} = {
        map {$_->color, $_->to_hashref} values %{$self->executions}};

    return $hashref;
}

sub to_json {
    my $self = shift;
    return $codec->pretty->encode($self->submission_data(@_));
}

__PACKAGE__->meta->make_immutable;

__END__
