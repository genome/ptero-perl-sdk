package Ptero::Builder::DAG;

use Moose;
use warnings FATAL => 'all';

use Data::Dump qw();
use Params::Validate qw(validate_pos :types);
use Set::Scalar qw();
use Graph::Directed qw();
use JSON qw();

use Ptero::Builder::Detail::Link;
use Ptero::Builder::Task;

with 'Ptero::Builder::Detail::Method';

my $codec = JSON->new()->canonical([1]);

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

    die sprintf("DAG (%s) has no task named %s",
        $self->name, Data::Dump::pp($name));
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
        _missing_task_errors
        _orphaned_task_errors
        _task_input_errors
        _task_output_errors
        _multiple_link_target_errors
        _cycle_errors
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
            'Duplicate task names on DAG (%s): %s',
            $self->name,
            Data::Dump::pp(sort @duplicates)
        );
    }

    return @errors;
}

sub _missing_task_errors {
    my $self = shift;
    my @errors;

    my $missing_task_names =
        ($self->_link_sources + $self->_link_destinations) - $self->_task_names;

    unless ($missing_task_names->is_empty) {
        push @errors, sprintf(
            'Links on DAG (%s) refer to non-existing tasks: %s',
            $self->name,
            Data::Dump::pp(sort $missing_task_names->members)
        );
    }

    return @errors;
}

sub _link_sources {
    my $self = shift;

    my $link_sources = new Set::Scalar;
    for my $link (@{$self->links}) {
        $link_sources->insert($link->source);
    }
    return $link_sources;
}

sub _link_destinations {
    my $self = shift;

    my $link_destinations = new Set::Scalar;
    for my $link (@{$self->links}) {
        $link_destinations->insert($link->destination);
    }
    return $link_destinations;
}

sub _task_names {
    my $self = shift;

    my $task_names = Set::Scalar->new('input connector', 'output connector');
    for my $task (@{$self->tasks}) {
        $task_names->insert($task->name);
    }
    return $task_names;
}

sub _orphaned_task_errors {
    my $self = shift;
    my @errors;

    my $orphaned_task_names =
        $self->_task_names - $self->_link_destinations - 'input connector';

    unless ($orphaned_task_names->is_empty) {
        push @errors, sprintf(
            'Orphaned task(s) on DAG (%s) named: %s',
            $self->name,
            Data::Dump::pp(sort $orphaned_task_names->members)
        );
    }

    return @errors;
}

sub _task_input_errors {
    my $self = shift;
    my @errors;

    my $mandatory_inputs = $self->_mandatory_inputs;
    for my $link (@{$self->links}) {
        my $destination = _encode_target(
            $link->destination, $link->destination_property);
        if ($mandatory_inputs->contains($destination)) {
            $mandatory_inputs->delete($destination);
        }
    }

    unless ($mandatory_inputs->is_empty) {
        push @errors, sprintf(
            'No links on DAG (%s) targeting mandatory input(s): %s',
            $self->name,
            (join ', ', sort $mandatory_inputs->members)
        );
    }

    return @errors;
}

sub _mandatory_inputs {
    my $self = shift;

    my $result = new Set::Scalar;

    for my $task (@{$self->tasks}) {
        for my $prop_name ($task->input_properties) {
            $result->insert(_encode_target($task->name, $prop_name));
        }
    }

    return $result;
}

sub _encode_target {
    my ($task_name, $prop_name) = @_;
    return Data::Dump::pp($task_name, $prop_name);
}

sub _task_output_errors {
    my $self = shift;
    my @errors;

    for my $link (@{$self->links}) {
        next if $link->is_external_input;

        my $task = $self->task_named($link->source);

        unless ($task->is_output_property($link->source_property)) {
            push @errors, sprintf(
                'Task %s in DAG (%s) has no output named %s',
                Data::Dump::pp($link->source),
                $self->name,
                Data::Dump::pp($link->source_property)
            );
        }
    }

    return @errors;
}

sub _multiple_link_target_errors {
    my $self = shift;
    my @errors;

    my %destinations;

    for my $link (@{$self->links}) {
        my $destination = _encode_target($link->destination,
            $link->destination_property);
        push @{$destinations{$destination}}, $link;
    }

    for my $destination (keys %destinations) {
        my @links = @{$destinations{$destination}};

        if (@links > 1) {
            push @errors, sprintf(
                "Multiple links on DAG (%s) target the same input_property:\n%s",
                $self->name,
                join(",\n", map { $_->to_string } @links),
            );
        }
    }

    return @errors;
}

sub _cycle_errors {
    my $self = shift;
    my @errors;

    my $g = Graph::Directed->new();
    for my $link (@{$self->links}) {
        $g->add_edge($link->source, $link->destination);
    }

    for my $region ($g->strongly_connected_components) {
        if (@$region > 1) {
            push @errors, sprintf(
                "A cycle exists in DAG (%s) involving the following tasks: %s",
                $self->name,
                Data::Dump::pp(sort @$region));
        }
    }
    return @errors;
}

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});

    $class->validate_hashref($hashref);

    my $self = $class->new(name => $hashref->{name});

    for my $link_hashref (@{$hashref->{parameters}->{links}}) {
        $self->link_tasks(%$link_hashref);
    }

    while (my ($task_name, $task_hashref) = each %{$hashref->{parameters}->{tasks}}) {
        $self->add_task(Ptero::Builder::Task->from_hashref(
            $task_hashref, $task_name));
    }

    return $self;
}

sub to_hashref {
    my $self = shift;

    return {
        name => $self->name,
        service => $self->service,
        parameters => {
            tasks => {map {$_->name, $_->to_hashref} @{$self->tasks}},
            links => [map {$_->to_hashref} @{$self->links}],
        },
    };
}

after 'validate_hashref' => sub {
    my ($class, $hashref) = @_;

    my %parameters = %{$hashref->{parameters}};
    for my $key (qw(tasks links)) {
        unless (exists $parameters{$key}) {
            die sprintf("DAG dashref missing required parameter (%s): %s",
                $key, Data::Dump::pp($hashref));
        }
    }

    unless (ref($parameters{tasks}) eq 'HASH') {
        die sprintf("The 'tasks' parameter must be a hashref not (%s): %s",
            ref($parameters{tasks}), Data::Dump::pp($hashref));
    }

    unless (ref($parameters{links}) eq 'ARRAY') {
        die sprintf("The 'links' parameter must be an arrayref not (%s): %s",
            ref($parameters{links}), Data::Dump::pp($hashref));
    }
};

sub from_json {
    my ($class, $json_string, $name) = validate_pos(@_, 1,
        {type => SCALAR}, {type => SCALAR});
    my $hashref = $codec->decode($json_string);

    $hashref->{name} = $name;
    $hashref->{parameters}->{tasks} = delete $hashref->{tasks};
    $hashref->{parameters}->{links} = delete $hashref->{links};
    $hashref->{service} = 'Workflow';

    return $class->from_hashref($hashref);
}

sub to_json {
    my $self = shift;
    my %p = Params::Validate::validate(@_, {
        pretty => {default => 0},
    });

    $self->validate;

    my $self_hashref = $self->to_hashref;
    my $json_hashref = {
        tasks => $self_hashref->{parameters}->{tasks},
        links => $self_hashref->{parameters}->{links},
    };

    if ($p{pretty}) {
        return $codec->pretty->encode($json_hashref);
    } else {
        return $codec->encode($json_hashref);
    }
}

sub validate {
    my $self = shift;
    my @errors = $self->validation_errors;
    if (@errors) {
        die sprintf(
            "DAG named %s failed validation:\n%s",
            $self->name, (join "\n", sort @errors)
        );
    }
    return;
}


__PACKAGE__->meta->make_immutable;
