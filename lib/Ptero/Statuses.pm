package Ptero::Statuses;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT_OK = qw(
    is_terminal
);

my $TERMINAL_STATUSES = Set::Scalar->new(qw(errored failed succeeded canceled));

sub is_terminal {
    my $status = shift;
    return $TERMINAL_STATUSES->contains($status);
}


1;
