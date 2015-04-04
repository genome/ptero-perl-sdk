package Ptero::Concrete::ShellCommand;

use Moose;
use warnings FATAL => 'all';
use Data::Dump qw(pp);

use Params::Validate qw(validate_pos :types);

use Ptero::Concrete::Detail::Workflow::Execution;

extends 'Ptero::Builder::ShellCommand';

has 'executions' => (
    is => 'rw',
    isa => 'HashRef[Ptero::Concrete::Detail::Workflow::Execution]',
);

sub _write_report {
    my $self = shift;
    my ($handle, $indent, $color) = validate_pos(@_, 1, 1, 1);
    return unless exists $self->executions->{$color};

    my $execution = $self->executions->{$color};
    printf $handle "%15s %10s %20s %13s %5s  %s%s\n",
        'ShellCommand',
        $execution->status,
        $execution->datetime_started,
        $execution->duration,
        $color,
        '. 'x$indent,
        $self->name;
}

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});

    my $hashref_executions = delete $hashref->{executions};
    my $self = $class->new(%$hashref);

    my %executions;
    while (my ($color, $execution_data) = each %$hashref_executions) {
        $executions{$color} = Ptero::Concrete::Detail::Workflow::Execution->from_hashref(
            $execution_data);
    }

    $self->executions(\%executions);

    return $self;
}

sub to_hashref {
    my $self = shift;
    my $hashref = $self->SUPER::to_hashref;
    $hashref->{executions} = {
        map {$_->color, $_->to_hashref} values %{$self->executions}};

    return $hashref;
}

__PACKAGE__->meta->make_immutable;
