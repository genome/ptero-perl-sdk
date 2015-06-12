package Ptero::Concrete::Workflow::Execution;

use strict;
use warnings FATAL => 'all';

use DateTime::Format::Strptime qw();
use DateTime qw();
use Date::Calc "Delta_DHMS";
use Set::Scalar;
use Ptero::Statuses qw(is_terminal);

my $DATETIME_PARSER = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d %H:%M:%S',
    on_error => 'croak'
);

sub new {
    my ($class, $hashref) = @_;

    my $self = {};
    $self->{begins} = $hashref->{begins};
    $self->{colors} = $hashref->{colors};
    $self->{color} = $hashref->{color};
    $self->{id} = $hashref->{id};
    $self->{parent_color} = $hashref->{parentColor};
    $self->{status} = $hashref->{status};
    $self->{status_history} = $hashref->{statusHistory};
    $self->{details_url} = $hashref->{detailsUrl};

    if (exists $hashref->{methodId}) {
        $self->{parent_type} = 'method';
        $self->{parent_id} = $hashref->{methodId};
    } else {
        $self->{parent_type} = 'task';
        $self->{parent_id} = $hashref->{taskId};
    }

    # only detailed executions have these
    $self->{data} = $hashref->{data};
    $self->{name} = $hashref->{name};
    $self->{inputs} = $hashref->{inputs};

    return bless $self, $class;
}

sub parallel_indexes {
    my $self = shift;
    # Here, we explicitly neglect the 0th index because
    # top level dags cannot be made parallel-by
    return map {$self->{colors}->[$_] - $self->{begins}->[$_]}
        (1..scalar(@{$self->{colors}})-1);
}

sub timestamp_for {
    my $self = shift;
    my $status = shift;

    my %lookup = map {$_->{status} => $_->{timestamp}} @{$self->{status_history}};
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

    if (is_terminal($self->{status})) {
        my $end_time = $self->timestamp_for($self->{status});
        my $end_datetime = $DATETIME_PARSER->parse_datetime($end_time);
        return $end_datetime;
    } else {
        return DateTime->now(time_zone => 'UTC');
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

1;
