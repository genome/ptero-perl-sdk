package Ptero;

use strict;
use warnings FATAL => 'all';

our $VERSION = "0.1.5";

use Log::Log4perl qw(:easy);

my $LOG_LEVEL_NAME = $ENV{PTERO_PERL_SDK_LOG_LEVEL} || 'INFO';
my $LOG_LEVEL = eval('$' . uc($LOG_LEVEL_NAME));
if ($@) {
    die "Couldn't determine logging level from PTERO_PERL_SDK_LOG_LEVEL='$LOG_LEVEL_NAME'";
}
Log::Log4perl->easy_init($LOG_LEVEL);


1;

__END__

=encoding utf-8

=head1 NAME

Ptero - a PERL client for the PTero services.

=head1 SYNOPSIS

stub

=head1 DESCRIPTION

stub

=head1 DEVELOPMENT

Dependencies are managed using L<Carton|https://github.com/perl-carton/carton>.
To use Carton with L<plenv|https://github.com/tokuhirom/plenv> you could do
something like this, assuming you have installed plenv and cloned this repo:

    $ export PTERO_PERL_VERSION=5.18.2 # or whatever version you want
    $ plenv install $PTERO_PERL_VERSION
    $ plenv install-cpanm
    $ cd ptero-perl-sdk
    $ plenv local $PTERO_PERL_VERSION
    $ cpanm install Carton
    $ plenv rehash

You could also setup Carton using the system Perl on Debian-based Linux:

    $ sudo apt-get install carton

Once your have Carton:

    $ carton install --deployment # from the root of this repo

To run tests:

    $ ./run-tests

=head1 LICENSE

GPLv3

=head1 AUTHOR

Michael Kiwala E<lt>mkiwala@genome.wustl.eduE<gt>
Ian Furgeson E<lt>ifurgeso@genome.wustl.eduE<gt>
David Morton E<lt>dmorton@cpan.orgE<gt>
Mark Burnett

=cut
