package Ptero::Statuses;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT_OK = qw(
    is_terminal
    is_success
    is_abnormal
    is_running
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


1;
