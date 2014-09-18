package Ptero::WorkflowBuilder::Operation;

use Moose;
use warnings FATAL => 'all';

use Data::Dump qw();
use Set::Scalar qw();

use Ptero::WorkflowBuilder::Detail::OperationMethod;

with 'Ptero::WorkflowBuilder::Detail::ConvertsToHashref';
with 'Ptero::WorkflowBuilder::Detail::Node';

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

sub to_hashref {
    my $self = shift;

    return {
        name    => $self->name,
        methods => [map { $_->to_hashref } @{$self->methods}],
    };
}

sub from_hashref {
    my ($class, $hashref) = @_;

    unless (exists $hashref->{methods} && ref($hashref->{methods}) eq 'ARRAY') {
        die 'Operation hashref must contain a methods arrayref: '
            . Data::Dump::pp($hashref);
    }

    my %hash = %$hashref; # copy the hashref

    my @methods = map {
        Ptero::WorkflowBuilder::Detail::OperationMethod->from_hashref($_)
    } @{$hashref->{methods}};

    delete $hash{methods};

    return $class->new(%hash, methods => \@methods);
}

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

