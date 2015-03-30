package Ptero::Concrete::Detail::Workflow::Execution;

use Moose;
use warnings FATAL => 'all';
use Set::Scalar;
use Ptero::Statuses qw(is_terminal);

use Params::Validate qw(validate_pos :types);

has 'name' => (
    is => 'ro',
    isa => 'Str',
);

has 'color' => (
    is => 'ro',
    isa => 'Int',
);

has 'parent_color' => (
    is => 'ro',
    isa => 'Int|Undef',
);

has 'data' => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

has 'colors' => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
);

has 'begins' => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
);

has 'inputs' => (
    is => 'ro',
    isa => 'HashRef',
);

has 'outputs' => (
    is => 'ro',
    isa => 'HashRef',
);

# status_history
# [ ['timestamp-1', 'status-1'],
#   ['timestamp-2', 'status-2'] ]
has 'status_history' => (
    is => 'ro',
    isa => 'ArrayRef[ArrayRef[Str]]',
);

override 'BUILDARGS' => sub {
    my $params = super();

    unless (defined $params->{data}) {
        delete $params->{data}
    }

    return $params;
};

sub timestamp_for {
    my $self = shift;
    my $status = shift;

    my %lookup = map {$_->[1] => $_->[0]} @{$self->status_history};
    return $lookup{$status} || '';
}

sub time_started {
    my $self = shift;

    return $self->timestamp_for('running');
}

sub time_ended {
    my $self = shift;

    if (is_terminal($self->status)) {
        return $self->timestamp_for($self->status)
    } else {
        return '';
    }
}

sub status {
    my $self = shift;
    return $self->status_history->[-1]->[-1];
}

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});

    my @status_history;
    foreach my $status (@{$hashref->{status_history}}) {
        push @status_history, [$status->{timestamp}, $status->{status}];
    }
    $hashref->{status_history} = \@status_history;

    return $class->new(%$hashref);
}

sub to_hashref {
    my $self = shift;
    my $result = {
        (map {$_ => $self->$_} qw(
            color parent_color data colors begins inputs outputs status))};

    $result->{status_history} = [map {
        {timestamp => $_->[0], status => $_->[1]} } @{$self->status_history}];

    return $result;
}

__PACKAGE__->meta->make_immutable;

__END__
