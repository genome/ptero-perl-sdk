package Ptero::WorkflowBuilder::Detail::Operation;

use Moose;
use warnings FATAL => 'all';

use Set::Scalar qw();

with 'Ptero::WorkflowBuilder::Detail::Element';

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has methods => (
    is => 'rw',
    isa => 'ArrayRef[Ptero::WorkflowBuilder::Detail::OperationMethod]',
    default => sub { [] },
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
# Inherited methods
# ------------------------------------------------------------------------------

sub to_hashref {
    my $self = shift;

    $self->validate;

    return {
        name    => $self->name,
        methods => [map { $_->to_hashref } @{$self->methods}],
    };
}

# ------------------------------------------------------------------------------
# Private methods
# ------------------------------------------------------------------------------

my $_INVALID_NAMES = new Set::Scalar('input connector', 'output connector');
sub validate {
    my $self = shift;

    if ($_INVALID_NAMES->contains($self->name)) {
        die sprintf("Operation name '%s' is not allowed",
            $self->name);
    }

    my @methods = @{$self->methods};

    unless (@methods) {
        die sprintf("Operation must have at least one method")
    }

    return;
};


__PACKAGE__->meta->make_immutable;

