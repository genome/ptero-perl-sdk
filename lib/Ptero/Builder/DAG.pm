package Ptero::Builder::DAG;

use Moose;
use warnings FATAL => 'all';

use Data::Dump qw();
use Params::Validate qw(validate_pos :types);
use Set::Scalar qw();
use Graph::Directed qw();

use Ptero::Builder::Detail::Link;
use Ptero::Builder::Task;

with 'Ptero::Builder::Detail::HasValidationErrors';
with 'Ptero::Builder::Detail::Method';

has tasks => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::Builder::Task]',
    default => sub { [] },
);

has links => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::Builder::Detail::Link]',
    default => sub { [] },
);

override 'BUILDARGS' => sub {
    my $params = super();
    $params->{service} = 'Workflow';
    return $params;
};

sub add_task {
    my ($self, $task) = @_;
    $self->tasks([@{$self->tasks}, $task]);
    return $task;
}

sub create_task {
    my $self = shift;
    my $task= Ptero::Builder::Task->new(@_);
    $self->add_task($task);
    return $task;
}

sub link_tasks {
    my $self = shift;
    my $link = Ptero::Builder::Detail::Link->new(@_);
    $self->links([@{$self->links}, $link]);
    return $link;
}

sub connect_input {
    my $self = shift;
    my %args = Params::Validate::validate(@_, {
            source_property => { type => SCALAR },
            destination => { type => SCALAR|OBJECT },
            destination_property => { type => SCALAR },
    });

    $self->link_tasks(%args);
    return;
}

sub connect_output {
    my $self = shift;
    my %args = Params::Validate::validate(@_, {
            source => { type => SCALAR|OBJECT },
            source_property => { type => SCALAR },
            destination_property => { type => SCALAR },
    });

    $self->link_tasks(%args);
    return;
}

sub task_named {
    my ($self, $name) = @_;

    for my $task (@{$self->tasks}) {
        if ($task->name eq $name) {
            return $task
        }
    }

    return;
}

sub input_properties {
    my $self = shift;
    my $properties = Set::Scalar->new($self->_property_names_from_links('is_external_input',
            'source_property'));
    return sort $properties->members();
};

sub output_properties {
    my $self = shift;
    return sort $self->_property_names_from_links('is_external_output',
        'destination_property');
}

sub _property_names_from_links {
    my ($self, $query_name, $property_holder) = @_;

    my $property_names = new Set::Scalar;

    for my $link (@{$self->links}) {
        if ($link->$query_name) {
            $property_names->insert($link->$property_holder);
        }
    }
    return $property_names->members;
}


sub validation_errors {
    my $self = shift;

    my @errors = map { $self->$_ } qw(
        _task_name_errors
    );

    for (@{$self->tasks}, @{$self->links}) {
        push @errors, $_->validation_errors;
    }

    return @errors;
}

sub _task_name_errors {
    my $self = shift;
    my @errors;

    my $task_names = new Set::Scalar;
    my @duplicates;
    for my $task (@{$self->tasks}) {
        if ($task_names->contains($task->name)) {
            push @duplicates, $task->name;
        }
        $task_names->insert($task->name);
    }

    if (@duplicates) {
        push @errors, sprintf(
            'Duplicate task names: %s',
            Data::Dump::pp(sort @duplicates)
        );
    }

    return @errors;
}


__PACKAGE__->meta->make_immutable;
