package Ptero::Builder::Detail::ConvertsToHashref;
use Moose::Role;
use warnings FATAL => 'all';

requires 'to_hashref';
requires 'from_hashref';

1;
