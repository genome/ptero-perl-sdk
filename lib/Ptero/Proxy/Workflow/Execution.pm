package Ptero::Proxy::Workflow::Execution;

use Moose;
use warnings FATAL => 'all';

use Params::Validate qw(validate_pos :types);
use Ptero::HTTP qw(get make_request_and_decode_response);
use Ptero::Concrete::Workflow::Execution;
use Ptero::Statuses qw(is_terminal is_success);

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has concrete_execution => (
    is => 'rw',
    isa => 'Ptero::Concrete::Workflow::Execution',
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
        my $execution_data = make_request_and_decode_response(method => 'GET',
            url => $args{url});
        $args{concrete_execution} = Ptero::Concrete::Workflow::Execution->new(
            $execution_data);
    }
    return \%args;
}

sub name {
    my $self = shift;
    return $self->concrete_execution->{name};
}

sub inputs {
    my $self = shift;
    return $self->concrete_execution->{inputs};
}

sub data {
    my $self = shift;
    return $self->concrete_execution->{data};
}

sub update_data {
    my $self = shift;
    my %new_data = @_;

    my %old_data = %{$self->data};
    my %patch_data = (%old_data, %new_data);

    my $new_execution_data = make_request_and_decode_response(method => 'PATCH',
        url => $self->url, data => {data => \%patch_data});

    $self->concrete_execution(Ptero::Concrete::Workflow::Execution->new(
        $new_execution_data));

    return;
}

sub set_outputs {
    my ($self, $outputs) = validate_pos(@_, 1, {type => HASHREF});

    my $new_execution_data = make_request_and_decode_response(method => 'PATCH',
        url => $self->url, data => {outputs => $outputs});

    $self->concrete_execution(Ptero::Concrete::Workflow::Execution->new(
        $new_execution_data));

    return;
}

sub child_workflow_proxies {
    my $self = shift;
    return $self->concrete_execution->child_workflow_proxies;
}

sub child_workflow_urls {
    my $self = shift;
    return $self->concrete_execution->{child_workflow_urls};
}


__PACKAGE__->meta->make_immutable;
