package Ptero::Concrete::Workflow;

use Moose;
use warnings FATAL => 'all';

use Params::Validate qw(validate_pos :types);
use JSON qw();

use Ptero::Concrete::Detail::Workflow::Execution;
use Ptero::Concrete::Detail::Workflow::Task;

extends 'Ptero::Builder::Workflow';

my $codec = JSON->new()->canonical([1]);

has 'executions' => (
    is => 'rw',
    isa => 'HashRef[Ptero::Concrete::Detail::Workflow::Execution]',
);

sub task_class { 'Ptero::Concrete::Detail::Workflow::Task' }

sub from_hashref {
    my ($class, $hashref) = validate_pos(@_, 1, {type => HASHREF});
    my $self = $class->SUPER::from_hashref($hashref);

    my %executions;
    while (my ($color, $execution_hashref) = each %{$hashref->{executions}}) {
        $executions{$color} = Ptero::Concrete::Detail::Workflow::Execution->from_hashref(
            $execution_hashref);
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

sub to_json {
    my $self = shift;
    return $codec->pretty->encode($self->submission_data(@_));
}

__PACKAGE__->meta->make_immutable;

__END__
