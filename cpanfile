requires 'perl' => '5.10.1';

requires "Data::Dump";
requires "File::Slurp";
requires "JSON";
requires "Log::Log4perl";
requires "Moose";
requires "MooseX::Getopt";
requires "Params::Validate";
requires "Set::Scalar";
requires "Test::Deep";

on 'test' => sub {
  requires "Test::Exception";
};
