use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {
      'Mojolicious' => '2.95',
      'Config::Tiny' => 0,
      'Data::Dumper' => 0,
      'Digest::SHA' => 0,
      'Email::Send::Gmail' => 0,
      'Email::Send' => 0,
      'File::Path' => 0,
      'File::Util' => 0,
      'Getopt::Long' => 0,
      'JSON' => 0,
      'MIME::EncWords' => 0,
      'MIME::Lite' => 0,
      'Store::CouchDB' => 0,
      'Text::Upskirt' => 0,
      'common::sense' => 0,
      'WWW::Facebook::API' => 0,
      'Store::CouchDB' => '2.8',
  },
  test      => {TESTS => 't/*.t'}
);
