package Ptero::Statuses;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT_OK = qw(
    is_terminal
    is_success
    is_abnormal
    is_running
    get_abbreviation
);

my $TERMINAL_STATUSES = Set::Scalar->new(qw(errored failed succeeded canceled));

sub is_terminal {
    my $status = shift;
    return $TERMINAL_STATUSES->contains($status);
}

sub is_success {
    my $status = shift;
    return $status eq 'succeeded';
}

sub is_abnormal {
    my $status = shift;
    return (is_terminal($status) and !is_success($status));
}

sub is_running {
    my $status = shift;
    return $status eq 'running';
}


my %STATUS_LETTERS = (
    'new' => 'N',
    'scheduled' => 'D',
    'running' => 'R',
    'succeeded' => 'S',
    'failed' => 'F',
    'errored' => 'E',
    'canceled' => 'C',
);

sub get_abbreviation {
    my $status = shift;
    return $STATUS_LETTERS{$status} || "U";
}


1;
