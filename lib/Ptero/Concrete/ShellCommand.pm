package Ptero::Concrete::ShellCommand;

use Moose;
use warnings FATAL => 'all';
use Data::Dump qw(pp);

use Params::Validate qw(validate_pos :types);

extends 'Ptero::Builder::ShellCommand';
with 'Ptero::Concrete::Detail::Roles::CanWriteReport';
with 'Ptero::Concrete::Detail::Roles::HasExecutions';

sub _write_report {
    my $self = shift;
    my ($handle, $indent, $color, $force) = $self->params_validator(@_);
    return unless exists $self->executions->{$color};

    my $execution = $self->executions->{$color};
    printf $handle $self->format_line,
        'ShellCommand',
        $execution->status,
        $execution->datetime_started,
        $execution->duration,
        join(', ', $execution->parallel_indexes),
        $self->indentation_str x $indent,
        $self->name;
}

__PACKAGE__->meta->make_immutable;
