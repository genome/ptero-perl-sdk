requires 'perl' => '5.10.1';

requires "File::Slurp";
requires "JSON";
requires "Log::Log4perl";
requires "Moose";
requires "MooseX::Getopt";
requires "Params::Validate";
requires "Test::Deep";
requires "Data::Dump";

on 'test' => sub {
  requires "Test::Exception";
};
