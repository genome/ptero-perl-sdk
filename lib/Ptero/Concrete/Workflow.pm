package Ptero::Concrete::Workflow;

use Moose;
use warnings FATAL => 'all';

use JSON qw();
use Params::Validate qw(validate_pos :types);

use Ptero::Concrete::DAG;

with 'Ptero::Builder::Detail::HasWebhooks';
with 'Ptero::Concrete::Detail::Roles::CanWriteReport';

my $codec = JSON->new()->canonical([1]);

has 'dag' => (
    is => 'ro',
    isa => 'Ptero::Concrete::DAG',
);

has 'inputs' => (
    is => 'ro',
    isa => 'HashRef',
);

has 'name' => (
    is => 'ro',
    isa => 'Str',
);

has 'status' => (
    is => 'ro',
    isa => 'Str',
);

has 'url' => (
    is => 'ro',
    isa => 'Str',
);

sub write_report {
    my $self = shift;
    my %p = Params::Validate::validate(@_, {
        handle => 1,
        indent => {default => 0},
    });

    $self->_write_report($p{handle}, $p{indent}, 0);
}

sub _write_report {
    my $self = shift;
    my ($handle, $indent, $color) = $self->params_validator(@_);

    printf $handle $self->format_line,
        'TYPE',
        'STATUS',
        'STARTED',
        'DURATION',
        'P-INDEX',
        '',
        'NAME';

    printf $handle $self->format_line,
        'Workflow',
        $self->status,
        '',
        '',
        '',
        $self->indentation_str x $indent,
        $self->name;

    for my $name ($self->dag->sorted_tasks) {
        my $task = $self->dag->task_named($name);
        $task->_write_report($handle, $indent+1, $color);
    }
}

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});
    return $class->new(%$hashref);
}

sub to_hashref {
    my $self = shift;

    return {
        dag => $self->dag,
        inputs => $self->inputs,
        name => $self->name,
        status => $self->status,
        url => $self->url,
    };
}

sub from_json {
    my ($class, $json_string, $url) = validate_pos(@_, 1,
        {type => SCALAR}, {type => SCALAR});
    my $hashref = $codec->decode($json_string);

    my $dag_hashref = {
        parameters => {
            tasks => $hashref->{tasks},
            links => $hashref->{links},
        },
        service => 'workflow',
        name => 'root',
    };

    if (exists $hashref->{webhooks}) {
        $dag_hashref->{parameters}->{webhooks} = $hashref->{webhooks};
    }

    my $dag = Ptero::Concrete::DAG->from_hashref($dag_hashref);

    my $workflow_hashref = {
        dag => $dag,
        inputs => $hashref->{inputs},
        name => $hashref->{name},
        status => $hashref->{status},
        url => $url,
    };

    return $class->from_hashref($workflow_hashref);
}

sub to_json {
    my $self = shift;

    my $dag_hashref = $self->dag->to_hashref;

    my $hashref = {
        tasks => $dag_hashref->{parameters}->{tasks},
        links => $dag_hashref->{parameters}->{links},
        inputs => $self->inputs,
        name => $self->name,
        status => $self->status,
    };

    if ($self->dag->has_webhooks) {
        $hashref->{webhooks} = $self->dag->webhooks
    }

    return $codec->pretty->encode($hashref);
}

__PACKAGE__->meta->make_immutable;

__END__
