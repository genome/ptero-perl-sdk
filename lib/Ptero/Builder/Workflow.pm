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

with 'Ptero::Builder::Detail::HasWebhooksInParameters';
with 'Ptero::Builder::Detail::Method';
with 'Ptero::Builder::Detail::Submittable';

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

has _links => (
    is => 'rw',
    isa => 'HashRef[HashRef[Ptero::Builder::Detail::Workflow::Link]]',
    default => sub { {} },
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
        name => {type => SCALAR, optional => 1},
        submit_url => {type => SCALAR, optional => 1},
    });

    my $submit_url = $p{submit_url} || $ENV{PTERO_WORKFLOW_SUBMIT_URL} || die
        "Must specify 'submit_url' or set PTERO_WORKFLOW_SUBMIT_URL env variable.";

    my $submission_data = $self->submission_data($p{inputs}, $p{name});
    if ($ENV{PTERO_WORKFLOW_EXECUTION_URL}) {
        $submission_data->{parentExecutionUrl} = $ENV{PTERO_WORKFLOW_EXECUTION_URL};
    }
    my $response = Ptero::HTTP::post($submit_url, $submission_data);

    unless ($response->code == 201) {
        die sprintf "Failed to submit workflow to '%s'.\n"
            ."Status Code (%s)\n"
            ."Request Body\n%s\n"
            ."Response Body\n%s\n",
            $submit_url, $response->code,
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
    return $self->add_task($task);
}

sub add_task {
    my ($self, $task) = @_;
    $self->tasks([@{$self->tasks}, $task]);
    return $task;
}

sub create_link {
    my $self = shift;
    my $link = Ptero::Builder::Detail::Workflow::Link->new(@_);
    return $self->add_link($link);
}

sub add_link {
    my ($self, $link) = @_;
    $self->links([@{$self->links}, $link]);
    $self->_links->{$link->source}->{$link->destination} = $link;
    return $link;
}

sub get_link {
    my $self = shift;
    my %p = Params::Validate::validate(@_, {
            source => { type => SCALAR|OBJECT },
            destination => { type => SCALAR|OBJECT }
    });
    my $source = ref($p{source}) ?
        $p{source}->name : $p{source};
    my $destination = ref($p{destination}) ?
        $p{destination}->name : $p{destination};
    return $self->_links->{$source}->{$destination};
}

sub add_data_flow {
    my $self = shift;
    my %p = Params::Validate::validate(@_, {
            source => { type => SCALAR|OBJECT,
                        default => 'input connector'},
            destination => { type => SCALAR|OBJECT,
                             default => 'output connector'},
            source_property => { type => SCALAR },
            destination_property => { type => SCALAR },
    });
    my $link = $self->get_link(source => $p{source},
        destination => $p{destination});

    $link = $self->create_link(
        source => $p{source},
        destination => $p{destination},
    ) unless $link;

    return $link->add_data_flow($p{source_property}, $p{destination_property});
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

sub external_input_links {
    my $self = shift;
    return grep {$_->is_external_input} @{$self->links};
}

sub known_input_properties {
    my $self = shift;

    my $property_names = Set::Scalar->new();
    for my $link ($self->external_input_links) {
        $property_names->insert($link->source_properties)
    }

    return sort $property_names->members();
};

sub external_output_links {
    my $self = shift;
    return grep {$_->is_external_output} @{$self->links};
}

sub has_possible_output_property {
    my ($self, $name) = @_;

    my $property_names = Set::Scalar->new();
    for my $link ($self->external_output_links) {
        $property_names->insert($link->destination_properties)
    }

    return $property_names->contains($name);
}

sub validation_errors {
    my $self = shift;

    my @errors = map { $self->$_ } qw(
        _task_name_errors
        _missing_task_errors
        _orphaned_task_errors
        _task_input_errors
        _task_output_errors
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

    my $missing_inputs = $self->_mandatory_inputs - $self->_existing_inputs;

    unless ($missing_inputs->is_empty) {
        push @errors, sprintf(
            'No links on Workflow (%s) targeting mandatory input(s): %s',
            $self->name,
            (join ', ', sort $missing_inputs->members)
        );
    }

    return @errors;
}

sub _existing_inputs {
    my $self = shift;

    my $existing_inputs = Set::Scalar->new();
    for my $link (@{$self->links}) {
        my $destination = $link->destination;
        if ($link->has_data_flow) {
            for my $properties_arrayref (values %{$link->data_flow}) {
                for my $property (@$properties_arrayref) {
                    $existing_inputs->insert(_encode_target(
                            $destination, $property));
                }
            }
        }
    }
    return $existing_inputs
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

        if ($link->has_data_flow) {
            for my $source_property (keys %{$link->data_flow}) {
                unless ($task->has_possible_output_property($source_property)) {
                    push @errors, sprintf(
                        'Task %s in Workflow (%s) has no output named %s',
                        Data::Dump::pp($link->source),
                        $self->name,
                        Data::Dump::pp($source_property)
                    );
                }
            }
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
        my $link = Ptero::Builder::Detail::Workflow::Link->new(%{$link_hashref});
        $self->links([@{$self->links}, $link]);
    }

    while (my ($task_name, $task_hashref) = each %{$hashref->{parameters}->{tasks}}) {
        my $task_class = $class->task_class;
        $self->add_task($task_class->from_hashref(
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
            die sprintf("Workflow hashref missing required parameter (%s): %s",
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
    return $class->from_json_hashref($hashref, $name);

}

sub from_json_hashref {
    my ($class, $hashref, $name) = validate_pos(@_, 1,
        {type => HASHREF}, {type => SCALAR});

    $hashref->{name} = $name;
    $hashref->{parameters}->{tasks} = delete $hashref->{tasks};
    $hashref->{parameters}->{links} = delete $hashref->{links};

    if (exists $hashref->{webhooks}) {
        $hashref->{parameters}->{webhooks} = delete $hashref->{webhooks};
    }
    $hashref->{service} = 'workflow';

    return $class->from_hashref($hashref);
}

sub submission_data {
    my ($self, $inputs, $name) = @_;

    $self->validate;

    my $self_hashref = $self->to_hashref;
    my $hashref = {
        tasks => $self_hashref->{parameters}->{tasks},
        links => $self_hashref->{parameters}->{links},
    };

    if (exists $self_hashref->{parameters}->{webhooks}) {
        $hashref->{webhooks} = $self_hashref->{parameters}->{webhooks};
    }

    if (defined $inputs) {
        $hashref->{inputs} = $inputs;
    }

    if (defined $name) {
        $hashref->{name} = $name;
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
    use Ptero::Builder::Job;

    my $workflow = Ptero::Builder::Workflow->new(name => 'test');

    my $shortcut_method = Ptero::Builder::Job->new(
            name => 'try to shortcut',
            service_url => 'http://example.com/v1',
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

    my $execute_method = Ptero::Builder::Job->new(
            name => 'try to execute',
            service_url => 'http://example.com/v1',
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

    $workflow->create_link(
        source_property => 'workflow_input_name',
        destination => $task,
        destination_property => 'task_input_name',
    );
    $workflow->create_link(
        source => $task,
        source_property => 'task_output_name',
        destination_property => 'workflow_output_name',
    );

=head1 DESCRIPTION

