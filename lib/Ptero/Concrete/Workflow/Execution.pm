package Ptero::Concrete::Workflow::Execution;

use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use DateTime::Format::Strptime qw();
use DateTime qw();
use Date::Calc "Delta_DHMS";
use Set::Scalar;
use Ptero::Statuses qw(is_terminal);
use Ptero::Proxy::Workflow;

sub new {
    my ($class, $hashref) = @_;

    my $self = {};
    $self->{begins} = $hashref->{begins};
    $self->{colors} = $hashref->{colors};
    $self->{color} = $hashref->{color};
    $self->{id} = $hashref->{id};
    $self->{parent_color} = $hashref->{parentColor};
    $self->{status} = $hashref->{status};
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

    $self->{status_history} = $hashref->{status_history} || [];

    $self->{child_workflow_urls} = Set::Scalar->new();
    if (exists $hashref->{childWorkflowUrls}) {
        $self->{child_workflow_urls}->insert(
            @{$hashref->{childWorkflowUrls}}
        );
    }

    return bless $self, $class;
}

sub add_status_history {
    my ($self, $status, $timestamp) = @_;
    push @{$self->{status_history}}, {status => $status, timestamp => $timestamp};
}

sub add_child_workflow_urls {
    my $self = shift;
    $self->{child_workflow_urls}->insert(@_);
}

sub child_workflow_proxies {
    my $self = shift;
    my $result = [];

    for my $workflow_url ($self->{child_workflow_urls}->members()) {
        push @$result, Ptero::Proxy::Workflow->new($workflow_url);
    }
    return $result;
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

    return $self->_parse_datetime($self->time_started);
}

sub datetime_ended {
    my $self = shift;

    if (is_terminal($self->{status})) {
        my $end_time = $self->timestamp_for($self->{status});
        my $end_datetime = $self->_parse_datetime($end_time);
        return $end_datetime;
    } else {
        return DateTime->now(time_zone => 'UTC');
    }
}

sub _parse_datetime {
    my $self = shift;
    my ($time) = @_;

    # Convert timezone: e.g., '-05:00' -> '-5000'
    $time =~ s/([-+]\d{2}):(\d{2})$/$1$2/;

    my $pattern = '%Y-%m-%d %H:%M:%S.%6N%z';
    my $parser = DateTime::Format::Strptime->new(pattern => $pattern);

    my $datetime = $parser->parse_datetime($time);
    unless (defined $datetime) {
        confess "Failed to parse time '$time' with pattern '$pattern'";
    }

    return $datetime;
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
