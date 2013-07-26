
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Generate POD documentation from Rinci function metadata",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Perinci-Sub-To-POD",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Perinci::Sub::To::POD",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::Which" => 0,
    "Locale::Maketext::Lexicon::Gettext" => 0,
    "Log::Any" => 0,
    "Markdown::Pod" => 0,
    "Moo" => 0,
    "Perinci::CmdLine" => "0.83",
    "Perinci::Sub::To::FuncBase" => 0,
    "Perinci::Sub::To::FuncBase::I18N" => 0,
    "Perinci::Sub::To::FuncBase::I18N::en" => 0,
    "Perinci::Sub::To::Text" => 0,
    "perl" => "5.010001"
  },
  "script_files" => [
    "bin/peri-func-doc"
  ],
  "test_requires" => {}
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
