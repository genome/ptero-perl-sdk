[![Build Status](https://travis-ci.org/genome/ptero-perl-sdk.png?branch=master)](https://travis-ci.org/genome/ptero-perl-sdk)
# NAME

Ptero - a PERL client for the PTero services.

# SYNOPSIS

stub

# DESCRIPTION

stub

# DEVELOPMENT

Dependencies are managed using [Carton](https://github.com/perl-carton/carton).
To use Carton with [plenv](https://github.com/tokuhirom/plenv) you could do
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

# LICENSE

GPLv3

# AUTHOR

 - Michael Kiwala <[mkiwala@genome.wustl.edu](mailto:mkiwala@genome.wustl.edu)>
 - Ian Ferguson <[iferguso@genome.wustl.edu](mailto:iferguso@genome.wustl.edu)>
 - David Morton <[dmorton@cpan.org](mailto:dmorton@cpan.org)>
 - Mark Burnett
