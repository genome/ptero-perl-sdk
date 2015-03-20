package Ptero::Statuses;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT_OK = qw(
    is_terminal
    is_success
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


1;
