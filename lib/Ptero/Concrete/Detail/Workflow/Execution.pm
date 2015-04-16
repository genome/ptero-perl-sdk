package Ptero::Concrete::Detail::Workflow::Execution;

use Moose;
use warnings FATAL => 'all';
use Set::Scalar;
use Ptero::Statuses qw(is_terminal);

use Params::Validate qw(validate_pos :types);
use DateTime::Format::Strptime qw();
use DateTime qw();
use Date::Calc "Delta_DHMS";

my $DATETIME_PARSER = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d %H:%M:%S',
    on_error => 'croak'
);


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

sub parallel_indexes {
    my $self = shift;
    # Here, we explicitly neglect the 0th index because
    # top level dags cannot be made parallel-by
    return map {$self->colors->[$_] - $self->begins->[$_]}
        (1..scalar(@{$self->colors})-1);
}

sub timestamp_for {
    my $self = shift;
    my $status = shift;

    my %lookup = map {$_->[1] => $_->[0]} @{$self->status_history};
    return $lookup{$status} || '';
}

sub time_started {
    my $self = shift;

    my $start_time = $self->timestamp_for('running');
    $start_time = $self->timestamp_for('errored') unless $start_time;
    $start_time = $self->timestamp_for('new') unless $start_time;

    return $start_time;
}

sub datetime_started {
    my $self = shift;

    return $DATETIME_PARSER->parse_datetime($self->time_started);
}

sub datetime_ended {
    my $self = shift;

    if (is_terminal($self->status)) {
        my $end_time = $self->timestamp_for($self->status);
        my $end_datetime = $DATETIME_PARSER->parse_datetime($end_time);
        return $end_datetime;
    } else {
        return DateTime->now(time_zone => 'local');
    }
}

sub duration {
    my $self = shift;

    return '' unless $self->time_started;
    return _resolve_duration($self->datetime_started, $self->datetime_ended);
}

sub _resolve_duration {
    my ($d1, $d2) = @_;

    my ($days, $hours, $minutes, $seconds) = Delta_DHMS(
        $d1->year, $d1->month, $d1->day, $d1->hour, $d1->minute, $d1->second,
        $d2->year, $d2->month, $d2->day, $d2->hour, $d2->minute, $d2->second);

    my $day_string = sprintf("%4s", $days   ? $days."d":"");

    return sprintf("$day_string %02d:%02d:%02d", $hours, $minutes, $seconds);
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
