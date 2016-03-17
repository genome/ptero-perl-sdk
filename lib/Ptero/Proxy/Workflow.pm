package Ptero::Proxy::Workflow;

use Moose;
use warnings FATAL => 'all';

use Params::Validate;
use Ptero::HTTP qw(get make_request_and_decode_response);
use Ptero::Concrete::Workflow;
use Ptero::Statuses qw(is_terminal is_success);

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has resource => (
    is => 'rw',
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
        $args{resource} = make_request_and_decode_response(method => 'GET',
            url => $args{url});
    }
    return \%args;
}

sub concrete_workflow {
    my $self = shift;
    return $self->_concrete_workflow($self->workflow_skeleton, $self->workflow_executions);
}

sub _concrete_workflow {
    my ($self, $skeleton_hashref, $executions) = @_;

    my $concrete_workflow = Ptero::Concrete::Workflow->new($skeleton_hashref);

    $concrete_workflow->add_executions($executions);

    return $concrete_workflow;
}

sub workflow_skeleton {
    my $self = shift;
    return make_request_and_decode_response(method => 'GET',
        url => $self->report_url('workflow-skeleton'));
}

sub workflow_executions {
    my $self = shift;

    # Fetch status updates before executions because you don't
    # want to find out you fetched a status update for an execution
    # that didn't exist when you fetched them.
    my $status_updates = $self->get_all_status_updates();

    my $executions = $self->get_all_executions();
    my %executions_hash = map {$_->{id}, $_} @{$executions};

    # attach status updates
    for my $status_update (@{$status_updates}) {
        my $execution_id = $status_update->{executionId};
        my $execution = $executions_hash{$execution_id};
        $execution->add_status_history(
            $status_update->{status},
            $status_update->{timestamp}
        );
    }

    # attach spawned workflows
    my $spawned_workflows = $self->get_spawned_workflows();
    for my $spawned_workflow (@{$spawned_workflows}) {
        my $execution_id = $spawned_workflow->{executionId};
        my $execution = $executions_hash{$execution_id};
        $execution->add_child_workflow_urls(
            @{$spawned_workflow->{spawnedWorkflowUrls}}
        );
    }

    return $executions;
}

sub get_all_executions {
    my $self = shift;

    my @executions;
    my $hashrefs = $self->get_all_hashrefs('executions',
        $self->report_url('limited-workflow-executions'));
    for my $hashref (@{$hashrefs}) {
        push @executions, Ptero::Concrete::Workflow::Execution->new($hashref);
    }
    return \@executions;
}

sub get_all_status_updates {
    my $self = shift;

    return $self->get_all_hashrefs('statusUpdates',
        $self->report_url('limited-workflow-status-updates'));
}

sub get_all_hashrefs {
    my ($self, $name, $url) = @_;

    my $remaining = 1;
    my @objects;
    while ($remaining > 0) {
        my $page = make_request_and_decode_response(method => 'GET',
            url => $url);
        $remaining = $page->{numRemaining};
        push @objects, @{$page->{$name}};
        $url = $page->{updateUrl};
    }
    return \@objects;
}

sub get_spawned_workflows {
    my $self = shift;

    my $result = make_request_and_decode_response(method => 'GET',
        url => $self->report_url('spawned-workflows'));
    return $result->{spawnedWorkflows};
}

sub workflow_summary {
    my $self = shift;
    return make_request_and_decode_response(method => 'GET',
        url => $self->report_url('workflow-summary'));
}

sub cancel {
    my $self = shift;
    make_request_and_decode_response(method => 'PATCH', url => $self->url,
        data => { is_canceled => 1 });
    return;
}

sub delete {
    my $self = shift;
    make_request_and_decode_response(method => 'DELETE', url => $self->url);
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

    my $r = make_request_and_decode_response(method => 'GET',
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

    my $workflow_output_report = make_request_and_decode_response(
        method => 'GET', url => $self->report_url('workflow-outputs'));

    return $workflow_output_report->{outputs};
}

__PACKAGE__->meta->make_immutable;
