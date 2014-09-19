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

my $codec = JSON->new()->canonical([1]);

has nodes => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Detail::Node]',
    default => sub { [] },
);

has links => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Detail::Link]',
    default => sub { [] },
);


sub add_node {
    my ($self, $node) = @_;
    push @{$self->nodes}, $node;
    return $node;
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

sub node_named {
    my ($self, $name) = @_;

    for my $node (@{$self->nodes}) {
        if ($node->name eq $name) {
            return $node
        }
    }

    return;
}

sub node_names {
    my $self = shift;

    my $node_names = Set::Scalar->new('input connector', 'output connector');
    for my $node (@{$self->nodes}) {
        $node_names->insert($node->name);
    }
    return $node_names;
}

sub sorted_links {
    my $self = shift;

    return [sort { $a->sort_key cmp $b->sort_key } @{$self->links}];
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

sub from_hashref {
    my ($class, $hashref) = @_;

    my $self = $class->new(
        name => $hashref->{name},
    );

    for my $link_hashref (@{$hashref->{links}}) {
        $self->add_link(Ptero::WorkflowBuilder::Detail::Link->from_hashref($link_hashref));
    }

    for my $node_hashref (@{$hashref->{nodes}}) {
        if (exists $node_hashref->{nodes}) {
            $self->add_node(Ptero::WorkflowBuilder::DAG->from_hashref($node_hashref));
        } elsif (exists $node_hashref->{methods}) {
            $self->add_node(Ptero::WorkflowBuilder::Operation->from_hashref($node_hashref));
        } else {
            die sprintf(
                'Could not determine the class to instantiate with hashref (%s)',
                Data::Dump::pp($node_hashref)
            );
        }
    }

    return $self;
}

sub to_hashref {
    my $self = shift;

    my @links = map {$_->to_hashref} @{$self->links};
    my @nodes = map {$_->to_hashref} @{$self->nodes};

    return {
        name => $self->name,
        links => \@links,
        nodes => \@nodes,
    };
}

sub to_json_hashref {
    my $self = shift;

    my @links = map $_->to_hashref, @{$self->sorted_links};

    my %node_hash;
    for my $node (@{$self->nodes}) {
        my $node_hashref = $node->to_hashref;
        my $name = delete $node_hashref->{name};
        $node_hash{$name} = $node_hashref;
    }

    return {
        name => $self->name,
        links => \@links,
        nodes => \%node_hash,
    };
}

sub encode_as_json {
    my $self = shift;

    $self->validate;

    my $hashref = $self->to_json_hashref;

    return $codec->encode($hashref);
}

##############################
# Validations
##############################

sub _validate_node_names_are_unique {
    my $self = shift;
    my @errors;

    my $node_names = new Set::Scalar;
    my @duplicates;
    for my $node (@{$self->nodes}) {
        if ($node_names->contains($node->name)) {
            push @duplicates, $node->name;
        }
        $node_names->insert($node->name);
    }

    if (@duplicates) {
        push @errors, sprintf(
            'Duplicate node names: %s',
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

sub _validate_link_node_consistency {
    my $self = shift;
    my @errors;

    my $node_names = $self->node_names;
    my $link_targets = $self->link_targets;

    my $invalid_link_targets = $link_targets - $node_names;
    my $orphaned_node_names = $node_names - $link_targets;

    unless ($invalid_link_targets->is_empty) {
        push @errors, sprintf(
            'Links have invalid targets: %s',
            Data::Dump::pp(sort $invalid_link_targets->members)
        );
    }
    unless ($orphaned_node_names->is_empty) {
        push @errors, sprintf(
            'Orphaned node names: %s',
            Data::Dump::pp(sort $orphaned_node_names->members)
        );
    }

    return @errors;
}

sub _encode_target {
    my ($self, $node_name, $prop_name) = @_;
    return Data::Dump::pp($node_name, $prop_name);
}

sub _get_mandatory_inputs {
    my $self = shift;

    my $result = new Set::Scalar;

    for my $node (@{$self->nodes}) {
        for my $prop_name ($node->input_properties) {
            $result->insert($self->_encode_target($node->name, $prop_name));
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

sub _validate_outputs_exist {
    my $self = shift;
    my @errors;

    for my $link (@{$self->links}) {
        my $node = $self->node_named($link->source);

        next unless defined $node;

        unless ($node->is_output_property($link->source_property)) {
            push @errors, sprintf(
                'Node %s has no output named %s',
                Data::Dump::pp($link->source),
                Data::Dump::pp($link->source_property)
            );
        }
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
        _validate_node_names_are_unique
        _validate_link_node_consistency
        _validate_mandatory_inputs
        _validate_outputs_exist
        _validate_link_targets_are_unique
    );

    # Cascade validations
    for (@{$self->nodes}, @{$self->links}) {
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
