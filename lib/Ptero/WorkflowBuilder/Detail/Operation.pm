package Ptero::WorkflowBuilder::Detail::Operation;

use Moose::Role;
use warnings FATAL => 'all';

use Carp qw(confess);
use Data::Dump qw();
use File::Slurp qw();
use IO::File qw();
use IO::Scalar qw();
use JSON qw();
use Set::Scalar qw();

use autodie qw(:io);

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has methods => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Detail::OperationMethod]',
    required => 1,
);

# has log_dir => (
#     is => 'rw',
#     isa => 'Str',
# );

# has parallel_by => (
#     is => 'rw',
#     isa => 'Maybe[Str]',
# );

# ------------------------------------------------------------------------------
# Abstract methods
# ------------------------------------------------------------------------------

requires 'from_hashref';

requires 'input_properties';
requires 'output_properties';
requires 'operation_type_attributes';

requires 'is_input_property';
requires 'is_output_property';


# ------------------------------------------------------------------------------
# Public methods
# ------------------------------------------------------------------------------

sub from_hashref {
    my ($class, $hashref) = @_;
    # XXX
}


# ------------------------------------------------------------------------------
# Inherited methods
# ------------------------------------------------------------------------------

sub to_hashref {
    my $self = shift;

    $self->validate;

    my $element = XML::LibXML::Element->new('operation');
    $element->setAttribute('name', $self->name);

    if (defined($self->parallel_by)) {
        $element->setAttribute('parallelBy', $self->parallel_by);
    }

    $element->addChild($self->_get_operation_type_xml_element);

    return $element;
}

my $_INVALID_NAMES = new Set::Scalar('input connector', 'output connector');
before validate => sub {
    my $self = shift;

    if ($_INVALID_NAMES->contains($self->name)) {
        die sprintf("Operation name '%s' is not allowed",
            $self->name);
    }

    return;
};


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

sub _get_operation_type_xml_element {
    my $self = shift;

    my $element = XML::LibXML::Element->new('operationtype');

    $element->setAttribute('typeClass', $self->operation_type);

    map {$self->_add_property_xml_element($element, 'inputproperty', $_)}
        $self->input_properties;
    map {$self->_add_property_xml_element($element, 'outputproperty', $_)}
        $self->output_properties;

    my %attributes = $self->operation_type_attributes;
    for my $attr_name (keys(%attributes)) {
        $element->setAttribute($attr_name, $attributes{$attr_name});
    }

    return $element;
}

sub _add_property_xml_element {
    my ($self, $element, $xml_tag, $text) = @_;

    my $inner_element = XML::LibXML::Element->new($xml_tag);
    $inner_element->appendText($text);
    $element->addChild($inner_element);

    return;
}

1;

