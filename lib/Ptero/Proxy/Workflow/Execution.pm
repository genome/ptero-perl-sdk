package Ptero::Proxy::Workflow::Execution;

use Moose;
use warnings FATAL => 'all';

use Params::Validate qw(validate_pos :types);
use Ptero::HTTP qw(get make_request_and_decode_repsonse);
use Ptero::Concrete::Detail::Workflow::Execution;
use Ptero::Statuses qw(is_terminal is_success);

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has concrete_execution => (
    is => 'ro',
    isa => 'Ptero::Concrete::Detail::Workflow::Execution',
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

# This fetches the concrete_execution unless it was passed in at construction.
sub BUILDARGS {
    my ($class, %args) = @_;

    unless ($args{concrete_execution}) {
        unless ($args{url}) {
            die "Cannot create a Ptero::Proxy::Workflow::Execution without a url";
        }
        my $execution_data = make_request_and_decode_repsonse(method => 'GET',
            url => $args{url});
       $args{concrete_execution} = Ptero::Concrete::Detail::Workflow::Execution->from_hashref(
           $execution_data);
    }
    return \%args;
}

sub inputs {
    my $self = shift;
    return $self->concrete_execution->inputs;
}

sub data {
    my $self = shift;
    return $self->concrete_execution->data;
}

sub set_outputs {
    my ($self, $outputs) = validate_pos(@_, 1, {type => HASHREF});

    my $r = Ptero::HTTP::patch($self->url, {outputs => $outputs});
    unless ($r->is_success) {
        die sprintf("Unexpected response code (%s: %s) while patching %s: %s",
            $r->code, $r->message, $self->url, pp($outputs));
    }
    return;
}


__PACKAGE__->meta->make_immutable;
