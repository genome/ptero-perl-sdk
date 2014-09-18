package Ptero::WorkflowBuilder::DAG;

use Moose;
use warnings FATAL => 'all';

use JSON;
use List::MoreUtils qw();
use Params::Validate qw();
use Set::Scalar qw();

use Ptero::WorkflowBuilder::Link;
use Ptero::WorkflowBuilder::Detail::Operation;

with 'Ptero::WorkflowBuilder::Detail::DAGStep';

has operations => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Detail::DAGStep]',
    default => sub { [] },
);

has links => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Link]',
    default => sub { [] },
);


sub add_operation {
    my ($self, $op) = @_;

    push @{$self->operations}, $op;

    return $op;
}

sub add_link {
    my ($self, $link) = @_;

    push @{$self->links}, $link;

    return $link;
}

sub create_link {
    my $self = shift;
    $self->add_link(Ptero::WorkflowBuilder::Link->new(@_));
    return;
}

sub connect_input {
    my $self = shift;
    my %args = Params::Validate::validate(@_, {
            input_property => { type => Params::Validate::SCALAR },
            destination => { type => Params::Validate::OBJECT },
            destination_property => { type => Params::Validate::SCALAR },
    });

    $self->add_link(Ptero::WorkflowBuilder::Link->new(
        source_property => $args{input_property},
        destination => $args{destination},
        destination_property => $args{destination_property},
    ));
    return;
}

sub connect_output {
    my $self = shift;
    my %args = Params::Validate::validate(@_, {
            source => { type => Params::Validate::OBJECT },
            source_property => { type => Params::Validate::SCALAR },
            output_property => { type => Params::Validate::SCALAR },
    });

    $self->add_link(Ptero::WorkflowBuilder::Link->new(
        source => $args{source},
        source_property => $args{source_property},
        destination_property => $args{output_property},
    ));
    return;
}

sub operation_named {
    my ($self, $name) = @_;

    for my $op (@{$self->operations}) {
        if ($op->name eq $name) {
            return $op
        }
    }

    return;
}

sub _property_names_from_links {
    my ($self, $query_name, $property_holder) = @_;

    my $property_names = new Set::Scalar;

    for my $link (@{$self->links}) {
        if ($link->$query_name) {
            $property_names->insert($link->$property_holder);
        }
    }
    return @{$property_names};
}

sub input_properties {
    my $self = shift;
    return sort $self->_property_names_from_links('external_input',
        'source_property');
}

sub output_properties {
    my $self = shift;
    return sort $self->_property_names_from_links('external_output',
        'destination_property');
}

sub is_input_property {
    my ($self, $property_name) = @_;

    return List::MoreUtils::any {$property_name eq $_} $self->input_properties;
}

sub is_output_property {
    my ($self, $property_name) = @_;

    return List::MoreUtils::any {$property_name eq $_} $self->output_properties;
}

sub from_hashref {
    my ($class, $hashref) = @_;

    my @links = map Ptero::WorkflowBuilder::Link->from_hashref($_),
        @{$hashref->{links}};

    my @operations;
    for my $op_hashref (@{$hashref->{operations}}) {
        if (exists $op_hashref->{operations}) {
            push @operations,
                Ptero::WorkflowBuilder::DAG->from_hashref($op_hashref);
        } elsif (exists $op_hashref->{methods}) {
            push @operations,
                Ptero::WorkflowBuilder::Detail::Operation->from_hashref($op_hashref);
        } else {
            die sprintf("Could not determine the class to instantiate with hashref (%s)",
                Data::Dump::pp($op_hashref));
        }
    }

    my $self = $class->new(
        name => $hashref->{name},
        links => \@links,
        operations => \@operations,
    );

    return $self;
}

sub to_hashref {
    my $self = shift;

    my @links = map {$_->to_hashref} @{$self->links};
    my @operations = map {$_->to_hashref} @{$self->operations};

    return {
        name => $self->name,
        links => \@links,
        operations => \@operations,
    }
}

sub _validate_operation_names_are_unique {
    my $self = shift;

    my $operation_names = new Set::Scalar;
    for my $op (@{$self->operations}) {
        if ($operation_names->contains($op->name)) {
            die sprintf(
                    "Workflow DAG '%s' contains multiple operations named '%s'",
                    $self->name, $op->name);
        }
        $operation_names->insert($op->name);
    }

    return;
}

sub _validate_linked_operation_ownership {
    my $self = shift;

    my $operation_names = new Set::Scalar;
    for my $op (@{$self->operations}) {
        $operation_names->insert($op->name);
    }

    my @linked_operations = map { $_->source, $_->destination } @{$self->links};

    my @unowned;

    for my $operation (@linked_operations) {
        unless ($operation_names->contains($operation->name)) {
            push @unowned, $operation->name;
        }
    }

    if (@unowned) {
        die sprintf (
            "Unowned operation (%s) linked in DAG (%s)",
            (join ", ", @unowned), $self->name
        );
    }

    return;
}

sub _encode_input {
    my ($self, $op_name, $property_name) = @_;
    my $js = JSON->new->allow_nonref;

    return $js->canonical->encode({
        operation_name => $op_name,
        property_name => $property_name,
    });
}

sub _get_mandatory_inputs {
    my $self = shift;

    my $result = new Set::Scalar;

    for my $op (@{$self->operations}) {
        for my $prop_name ($op->input_properties) {
            $result->insert($self->_encode_input($op->name, $prop_name));
        }
    }

    return $result;
}

sub _validate_mandatory_inputs {
    my $self = shift;

    my $mandatory_inputs = $self->_get_mandatory_inputs;
    for my $link (@{$self->links}) {
        my $destination = $link->destination_to_string;
        if ($mandatory_inputs->contains($destination)) {
            $mandatory_inputs->delete($destination);
        }
    }

    unless ($mandatory_inputs->is_empty) {
        die sprintf(
            "No links targetting mandatory input(s): %s",
            $mandatory_inputs
        );
    }
}

sub _validate_non_conflicting_inputs {
    my $self = shift;

    my %destinations;

    for my $link (@{$self->links}) {
        my $destination = $link->destination_to_string;
        push @{$destinations{$destination}}, $link;
    }

    my @errors;
    for my $destination (keys %destinations) {
        my @links = @{$destinations{$destination}};

        if (@links > 1) {
            push @errors, sprintf(
                'Destination %s is targeted by multiple links from: %s',
                $destination, (join ', ', map { $_->source_as_string } @links)
            );
        }
    }

    if (@errors) {
        die join "\n", ('Conflicting inputs:', @errors);
    }
}

sub validate {
    my $self = shift;

    $self->_validate_operation_names_are_unique;
    $self->_validate_linked_operation_ownership;
    $self->_validate_mandatory_inputs;
    $self->_validate_non_conflicting_inputs;

    # Cascade validations
    $_->validate for (@{$self->operations}, @{$self->links});

    return;
}

sub _add_operations_from_hashref {
    my ($self, $hashref) = @_;

    for my $operation (@{$hashref->{workflow}{operations}}) {
        my $op = Ptero::WorkflowBuilder::Detail::Operation->from_hashref($operation);
        $self->add_operation($op);
    }
}

sub _add_links_from_hashref {
    my ($self, $hashref) = @_;

    for my $link (@{$hashref->{workflow}{links}}) {
        my $source_op = $self->operation_named(
                $link->{source});
        my $destination_op = $self->operation_named(
                $link->{destination});

        my %link_params = (
            source_property => $link->{source_property},
            destination_property => $link->{destination_property},
        );
        if (defined($source_op)) {
            $link_params{source} = $source_op;
        }
        if (defined($destination_op)) {
            $link_params{destination} = $destination_op;
        }
        my $link = Ptero::WorkflowBuilder::Link->new(%link_params);
        $self->add_link($link);
    }
}


__PACKAGE__->meta->make_immutable;

