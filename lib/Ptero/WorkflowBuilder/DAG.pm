package Ptero::WorkflowBuilder::DAG;

use Moose;
use warnings FATAL => 'all';

use Data::Dump qw();
use JSON;
use List::MoreUtils qw();
use Params::Validate qw();
use Set::Scalar qw();

use Ptero::WorkflowBuilder::Detail::Link;
use Ptero::WorkflowBuilder::Operation;

with 'Ptero::WorkflowBuilder::Detail::HasValidationErrors';
with 'Ptero::WorkflowBuilder::Detail::Node';

has operations => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Detail::Node]',
    default => sub { [] },
);

has links => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Detail::Link]',
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
    my $link = Ptero::WorkflowBuilder::Detail::Link->new(@_);
    $self->add_link($link);
    return $link;
}

sub connect_input {
    my $self = shift;
    my %args = Params::Validate::validate(@_, {
            source_property => { type => Params::Validate::SCALAR },
            destination => { type => Params::Validate::SCALAR },
            destination_property => { type => Params::Validate::SCALAR },
    });

    $self->create_link(%args);
    return;
}

sub connect_output {
    my $self = shift;
    my %args = Params::Validate::validate(@_, {
            source => { type => Params::Validate::SCALAR },
            source_property => { type => Params::Validate::SCALAR },
            destination_property => { type => Params::Validate::SCALAR },
    });

    $self->create_link(%args);
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

    my $self = $class->new(
        name => $hashref->{name},
    );

    for my $link_hashref (@{$hashref->{links}}) {
        $self->add_link(Ptero::WorkflowBuilder::Detail::Link->from_hashref($link_hashref));
    }

    for my $op_hashref (@{$hashref->{operations}}) {
        if (exists $op_hashref->{operations}) {
            $self->add_operation(Ptero::WorkflowBuilder::DAG->from_hashref($op_hashref));
        } elsif (exists $op_hashref->{methods}) {
            $self->add_operation(Ptero::WorkflowBuilder::Operation->from_hashref($op_hashref));
        } else {
            die sprintf(
                'Could not determine the class to instantiate with hashref (%s)',
                Data::Dump::pp($op_hashref)
            );
        }
    }

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
    my @errors;

    my $operation_names = new Set::Scalar;
    my @duplicates;
    for my $op (@{$self->operations}) {
        if ($operation_names->contains($op->name)) {
            push @duplicates, $op->name;
        }
        $operation_names->insert($op->name);
    }

    if (@duplicates) {
        push @errors, sprintf(
            'Duplicate operation names: %s',
            Data::Dump::pp(sort @duplicates)
        );
    }

    return @errors;
}

sub link_targets {
    my $self = shift;

    my $link_targets = new Set::Scalar;
    for my $link (@{$self->links}) {
        $link_targets->insert($link->source);
        $link_targets->insert($link->destination);
    }
    return $link_targets;
}

sub operation_names {
    my $self = shift;

    my $operation_names = Set::Scalar->new('input connector', 'output connector');
    for my $operation (@{$self->operations}) {
        $operation_names->insert($operation->name);
    }
    return $operation_names;
}

sub _validate_link_operation_consistency {
    my $self = shift;
    my @errors;

    my $operation_names = $self->operation_names;
    my $link_targets = $self->link_targets;

    my $invalid_link_targets = $link_targets - $operation_names;
    my $orphaned_operation_names = $operation_names - $link_targets;

    unless ($invalid_link_targets->is_empty) {
        push @errors, sprintf(
            'Links have invalid targets: %s',
            Data::Dump::pp(sort $invalid_link_targets->members)
        );
    }
    unless ($orphaned_operation_names->is_empty) {
        push @errors, sprintf(
            'Orphaned operation names: %s',
            Data::Dump::pp(sort $orphaned_operation_names->members)
        );
    }

    return @errors;
}

sub _encode_target {
    my ($self, $op_name, $prop_name) = @_;
    return Data::Dump::pp($op_name, $prop_name);
}

sub _get_mandatory_inputs {
    my $self = shift;

    my $result = new Set::Scalar;

    for my $op (@{$self->operations}) {
        for my $prop_name ($op->input_properties) {
            $result->insert($self->_encode_target($op->name, $prop_name));
        }
    }

    return $result;
}

sub _validate_mandatory_inputs {
    my $self = shift;
    my @errors;

    my $mandatory_inputs = $self->_get_mandatory_inputs;
    for my $link (@{$self->links}) {
        my $destination = $self->_encode_target(
            $link->destination, $link->destination_property);
        if ($mandatory_inputs->contains($destination)) {
            $mandatory_inputs->delete($destination);
        }
    }

    unless ($mandatory_inputs->is_empty) {
        push @errors, sprintf(
            'No links targeting mandatory input(s): %s',
            # $mandatory_inputs->members are already pp'd, so we can just join
            (join ', ', sort $mandatory_inputs->members)
        );
    }

    return @errors;
}

sub _validate_link_targets_are_unique {
    my $self = shift;
    my @errors;

    my %destinations;

    for my $link (@{$self->links}) {
        my $destination = $link->destination_to_string;
        push @{$destinations{$destination}}, $link;
    }

    for my $destination (keys %destinations) {
        my @links = @{$destinations{$destination}};

        if (@links > 1) {
            push @errors, sprintf(
                'Destination %s is targeted by multiple links from: %s',
                Data::Dump::pp($destination),
                Data::Dump::pp(sort map { $_->source_to_string } @links)
            );
        }
    }

    return @errors;
}

sub validation_errors {
    my $self = shift;

    my @errors = map { $self->$_ } qw(
        _validate_operation_names_are_unique
        _validate_link_operation_consistency
        _validate_mandatory_inputs
        _validate_link_targets_are_unique
    );

    # Cascade validations
    for (@{$self->operations}, @{$self->links}) {
        push @errors, $_->validation_errors;
    }

    return @errors;
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
