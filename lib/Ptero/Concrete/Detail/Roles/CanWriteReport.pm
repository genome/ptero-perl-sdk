package Ptero::Concrete::Detail::Roles::CanWriteReport;

use Moose::Role;
use warnings FATAL => 'all';
use Params::Validate qw(validate_pos :types);

sub indentation_str {
    return '. ';
}

sub format_line {
    return "%15s %10s %20s %13s %5s  %s%s\n";
}

sub params_validator {
    my $self = shift;
    return validate_pos(@_,
        {type => HANDLE},
        {type => SCALAR},
        {type => SCALAR},
        {type => SCALAR, default => 0},
    );
}

requires '_write_report';

1;
