package Ptero::Proxy::Workflow;

use Moose;
use warnings FATAL => 'all';

use Params::Validate;
use Ptero::HTTP qw(get_decoded_resource);

my @COMPLETE_STATUSES = qw(success failure error);

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

sub wait {
    my $self = shift;
    my %p = Params::Validate::validate(@_, {
        polling_interval => {default => 120},
    });

    while ($self->is_running) {
        sleep $p{polling_interval};
    }

    return;
}

sub is_running {
    my $self = shift;
    my $r = get_decoded_resource(url => $self->url);
    return !(grep {
            defined($r->{status}) and ($r->{status} eq $_)
        } @COMPLETE_STATUSES);
}

sub outputs {
    my $self = shift;

    my $workflow_detail = get_decoded_resource(url => $self->url);
    my $workflow_output_report = get_decoded_resource(
        url => $workflow_detail->{reports}->{'workflow-outputs'});

    return $workflow_output_report->{outputs};
}

__PACKAGE__->meta->make_immutable;
