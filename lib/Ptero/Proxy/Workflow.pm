package Ptero::Proxy::Workflow;

use Moose;
use warnings FATAL => 'all';

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

__PACKAGE__->meta->make_immutable;
