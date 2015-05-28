package Ptero::Proxy::Workflow;

use Moose;
use warnings FATAL => 'all';

use Params::Validate;
use Ptero::HTTP qw(get make_request_and_decode_repsonse);
use Ptero::Concrete::Workflow;
use Ptero::Statuses qw(is_terminal is_success);

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has resource => (
    is => 'ro',
    isa => 'HashRef',
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

# This fetches the resource unless it was passed in at construction.
sub BUILDARGS {
    my ($class, %args) = @_;

    unless ($args{resource}) {
        unless ($args{url}) {
            die "Cannot create a Ptero::Proxy::Workflow without a url";
        }
        $args{resource} = make_request_and_decode_repsonse(method => 'GET',
            url => $args{url});
    }
    return \%args;
}

sub concrete_workflow {
    my $self = shift;

    my $hashref = make_request_and_decode_repsonse(method => 'GET',
        url => $self->report_url('workflow-skeleton'));

    my $concrete_workflow = Ptero::Concrete::Workflow->new($hashref);
    $concrete_workflow->register_components();

    my $data = make_request_and_decode_repsonse(method => 'GET',
        url => $self->report_url('workflow-executions'));
    $concrete_workflow->create_executions($data->{executions});

    return $concrete_workflow;
}

sub cancel {
    my $self = shift;
    make_request_and_decode_repsonse(method => 'PATCH', url => $self->url,
        data => { is_canceled => 1 });
    return;
}

sub wait {
    my $self = shift;
    my %p = Params::Validate::validate(@_, {
        polling_interval => {default => 120},
    });

    while ($self->is_running) {
        sleep $p{polling_interval};
    }

    return $self->status;
}

sub name {
    my ($self) = @_;
    return $self->resource->{name};
}

sub report_url {
    my ($self, $report_name) = @_;
    if (exists $self->resource->{reports}->{$report_name}) {
        return $self->resource->{reports}->{$report_name};
    } else {
        die sprintf("No report named (%s) found on workflow (%s)",
            $report_name, $self->url);
    }
}

sub status {
    my $self = shift;

    my $r = make_request_and_decode_repsonse(method => 'GET',
        url => $self->report_url('workflow-status'));
    return $r->{status};
}

sub is_running {
    my $self = shift;

    return !is_terminal($self->status);
}

sub has_succeeded {
    my $self = shift;
    return is_success($self->status);
}

sub outputs {
    my $self = shift;

    my $workflow_output_report = make_request_and_decode_repsonse(
        method => 'GET', url => $self->report_url('workflow-outputs'));

    return $workflow_output_report->{outputs};
}

__PACKAGE__->meta->make_immutable;
