package Ptero::Proxy::LSF;

use Moose;
use warnings FATAL => 'all';

use Params::Validate;
use Ptero::HTTP qw(get make_request_and_decode_response);

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

# This allows ->new($url) as well as ->new(url => $url) construction styles
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if (@_ == 1 && !ref $_[0]) {
        return $class->$orig(url => $_[0]);
    }
    else {
        return $class->$orig(@_);
    }
};

sub update {
    my $self = shift;
    my $values = shift;

    make_request_and_decode_response(method => 'PATCH', url => $self->url,
        data => $values);
    return;
}

sub job_data {
    my $self = shift;

    return make_request_and_decode_response(method => 'GET', url => $self->url);
}

__PACKAGE__->meta->make_immutable;
