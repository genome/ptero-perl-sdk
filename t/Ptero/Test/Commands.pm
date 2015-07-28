package Ptero::Test::Commands;

use strict;
use warnings FATAL => 'all';

sub echo_test { shift }
sub fail_test { die "on purpose"; }
sub sleep_echo_test { sleep(2); return shift }
sub sleep_fail_test { sleep(2); die "Bad news"; }


1;
