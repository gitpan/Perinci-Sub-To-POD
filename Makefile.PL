
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Generate POD documentation from Rinci function metadata",
  "AUTHOR" => "Steven Haryanto <stevenharyanto\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Perinci-Sub-To-POD",
  "EXE_FILES" => [
    "bin/peri-func-doc"
  ],
  "LICENSE" => "perl",
  "NAME" => "Perinci::Sub::To::POD",
  "PREREQ_PM" => {
    "Data::Dump" => 0,
    "File::Which" => 0,
    "Locale::Maketext::Lexicon::Gettext" => 0,
    "Log::Any" => 0,
    "Markdown::Pod" => 0,
    "Moo" => 0,
    "Perinci::Access" => 0,
    "Perinci::CmdLine" => "0.83",
    "Perinci::Sub::GetArgs::Argv" => 0,
    "Perinci::Sub::To::FuncBase" => "0.28",
    "Perinci::Sub::To::FuncBase::I18N" => "0.28",
    "Perinci::Sub::To::FuncBase::I18N::en" => "0.28",
    "Perinci::Sub::To::Text" => "0.28",
    "Perinci::Sub::Util" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.08",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dump" => 0,
  "File::Spec" => 0,
  "File::Which" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Locale::Maketext::Lexicon::Gettext" => 0,
  "Log::Any" => 0,
  "Markdown::Pod" => 0,
  "Moo" => 0,
  "Perinci::Access" => 0,
  "Perinci::CmdLine" => "0.83",
  "Perinci::Sub::GetArgs::Argv" => 0,
  "Perinci::Sub::To::FuncBase" => "0.28",
  "Perinci::Sub::To::FuncBase::I18N" => "0.28",
  "Perinci::Sub::To::FuncBase::I18N::en" => "0.28",
  "Perinci::Sub::To::Text" => "0.28",
  "Perinci::Sub::Util" => 0,
  "Test::More" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



