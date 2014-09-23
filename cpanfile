requires 'perl' => '5.10.1';

requires "Data::Dump";
requires "File::Slurp";
requires "Graph";
requires "JSON";
requires "Log::Log4perl";
requires "Moose";
requires "MooseX::Aliases";
requires "Params::Validate";
requires "Set::Scalar";

on 'test' => sub {
    requires "Test::Exception";
    requires "Devel::Cover";
    requires "Devel::Cover::Report::Coveralls"
};
