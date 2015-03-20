package Ptero::Builder::Workflow;

use Moose;
use warnings FATAL => 'all';

use Data::Dump qw();
use Params::Validate qw(validate_pos :types);
use Set::Scalar qw();
use Graph::Directed qw();
use JSON qw();

use Ptero::Builder::Detail::Workflow::Link;
use Ptero::Builder::Detail::Workflow::Task;
use Ptero::HTTP;

with 'Ptero::Builder::Detail::Method', 'Ptero::Builder::Detail::Submittable';

my $codec = JSON->new()->canonical([1]);

has tasks => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::Builder::Detail::Workflow::Task]',
    default => sub { [] },
);

has links => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::Builder::Detail::Workflow::Link]',
    default => sub { [] },
);

override 'BUILDARGS' => sub {
    my $params = super();
    $params->{service} = 'workflow';
    return $params;
};

sub submit {
    my $self = shift;
    my %p = Params::Validate::validate(@_, {
        inputs => {type => HASHREF, optional => 1},
    });

    my $url = $ENV{PTERO_WORKFLOW_SUBMIT_URL};
    my $submission_data = $self->submission_data($p{inputs});
    my $response = Ptero::HTTP::post($url, $submission_data);

    unless ($response->code == 201) {
        die sprintf "Failed to submit workflow to '%s'.\n"
            ."Status Code (%s)\n"
            ."Request Body\n%s\n"
            ."Response Body\n%s\n",
            $url, $response->code,
            Data::Dump::pp($submission_data), $response->content;
    }

    require Ptero::Proxy::Workflow;  # silent, but bad news if done at compile-time
    return Ptero::Proxy::Workflow->new(
        url => $response->header('Location'),
        resource => Ptero::HTTP::decode_response($response),
    );
}

sub create_task {
    my $self = shift;
    my $task= Ptero::Builder::Detail::Workflow::Task->new(@_);
    return $self->_add_task($task);
}

sub _add_task {
    my ($self, $task) = @_;
    $self->tasks([@{$self->tasks}, $task]);
    return $task;
}

sub link_tasks {
    my $self = shift;
    my $link = Ptero::Builder::Detail::Workflow::Link->new(@_);
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

    die sprintf("Workflow (%s) has no task named %s",
        $self->name, Data::Dump::pp($name));
}

sub known_input_properties {
    my $self = shift;
    my $properties = $self->_property_names_from_links('is_external_input',
            'source_property');
    return sort $properties->members();
};

sub has_possible_output_property {
    my ($self, $name) = validate_pos(@_, 1, {type => SCALAR});
    my $output_properties = $self->_property_names_from_links('is_external_output',
        'destination_property');
    return $output_properties->contains($name);
}

sub _property_names_from_links {
    my ($self, $query_name, $property_holder) = @_;

    my $property_names = new Set::Scalar;

    for my $link (@{$self->links}) {
        if ($link->$query_name) {
            $property_names->insert($link->$property_holder);
        }
    }
    return $property_names;
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
            'Duplicate task names on Workflow (%s): %s',
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
            'Links on Workflow (%s) refer to non-existing tasks: %s',
            $self->name,
            Data::Dump::pp(sort $missing_task_names->members)
        );
    }

    return @errors;
}

sub _link_sources {
    my $self = shift;

    return Set::Scalar->new(map {$_->source} @{$self->links});
}

sub _link_destinations {
    my $self = shift;

    return Set::Scalar->new(map {$_->destination} @{$self->links});
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
            'Orphaned task(s) on Workflow (%s) named: %s',
            $self->name,
            Data::Dump::pp(sort $orphaned_task_names->members)
        );
    }

    return @errors;
}

sub _task_input_errors {
    my $self = shift;
    my @errors;

    my $existing_inputs = Set::Scalar->new(
        map {_encode_target($_->destination, $_->destination_property)} @{$self->links}
    );
    my $missing_inputs = $self->_mandatory_inputs - $existing_inputs;

    unless ($missing_inputs->is_empty) {
        push @errors, sprintf(
            'No links on Workflow (%s) targeting mandatory input(s): %s',
            $self->name,
            (join ', ', sort $missing_inputs->members)
        );
    }

    return @errors;
}

sub _mandatory_inputs {
    my $self = shift;

    my $result = new Set::Scalar;

    for my $task (@{$self->tasks}) {
        for my $prop_name ($task->known_input_properties) {
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

        unless ($task->has_possible_output_property($link->source_property)) {
            push @errors, sprintf(
                'Task %s in Workflow (%s) has no output named %s',
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
                "Multiple links on Workflow (%s) target the same input_property:\n%s",
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
                "A cycle exists in Workflow (%s) involving the following tasks: %s",
                $self->name,
                Data::Dump::pp(sort @$region));
        }
    }
    return @errors;
}

sub task_class { 'Ptero::Builder::Detail::Workflow::Task' }

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});

    $class->validate_hashref($hashref);

    my $self = $class->new(name => $hashref->{name});

    for my $link_hashref (@{$hashref->{parameters}->{links}}) {
        $self->link_tasks(%$link_hashref);
    }

    while (my ($task_name, $task_hashref) = each %{$hashref->{parameters}->{tasks}}) {
        my $task_class = $class->task_class;
        $self->_add_task($task_class->from_hashref(
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
            die sprintf("Workflow dashref missing required parameter (%s): %s",
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
    $hashref->{service} = 'workflow';

    return $class->from_hashref($hashref);
}

sub submission_data {
    my ($self, $inputs) = @_;

    $self->validate;

    my $self_hashref = $self->to_hashref;
    my $hashref = {
        tasks => $self_hashref->{parameters}->{tasks},
        links => $self_hashref->{parameters}->{links},
    };

    if (defined $inputs) {
        $hashref->{inputs} = $inputs;
    }

    return $hashref;
}

sub to_json {
    my $self = shift;
    return $codec->pretty->encode($self->submission_data(@_));
}

sub validate {
    my $self = shift;
    my @errors = $self->validation_errors;
    if (@errors) {
        die sprintf(
            "Workflow named %s failed validation:\n%s",
            $self->name, (join "\n", sort @errors)
        );
    }
    return;
}


__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

Ptero::Builder::Workflow - Class that represents a Ptero workflow prior to
submission

=head1 SYNOPSIS

    use Ptero::Builder::Workflow;
    use Ptero::Builder::ShellCommand;

    my $workflow = Ptero::Builder::Workflow->new(name => 'test');

    my $shortcut_method = Ptero::Builder::ShellCommand->new(
            name => 'try to shortcut',
            parameters => {
                commandLine => [
                    'ptero-perl-subroutine-wrapper',
                    '--package' => 'Some::Perl::Module',
                    '--subroutine => 'shortcut',
                ],
                environment => {PATH => <path that includes 'ptero-perl-subroutine-wrapper'>},
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );

    my $execute_method = Ptero::Builder::ShellCommand->new(
            name => 'try to execute',
            parameters => {
                commandLine => [
                    'ptero-perl-subroutine-wrapper',
                    '--package' => 'Some::Perl::Module',
                    '--subroutine => 'execute',
                ],
                environment => {PATH => <path that includes 'ptero-perl-subroutine-wrapper'>},
                user => $ENV{USER},
                workingDirectory => '/tmp'
            },
    );

    my $task = $workflow->create_task(
        name => 'run some perl module',
        methods => [$shortcut_method, $execute_method],
    );

    $workflow->connect_input(
        source_property => 'workflow_input_name',
        destination => $task,
        destination_property => 'task_input_name',
    );
    $workflow->connect_output(
        source => $task,
        source_property => 'task_output_name',
        destination_property => 'workflow_output_name',
    );

=head1 DESCRIPTION

