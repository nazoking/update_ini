#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use IO::File;
require $FindBin::Bin.'/../update_ini.pl';
package update_ini;
use Test::More qw(no_plan);

sub up_test{
  my $in = shift;
  my $ci = shift;
  my $checkers = &parse_checkers($ci);
  my $outh = IO::File->new();
  my $out = "";
  open $outh, '>', \$out;
  my $inh = IO::File->new();
  open $inh, '<', \$in;
  my @ina = $inh->getlines;
  my $options = {};
  &update($options,$checkers,\@ina,$outh);
  $inh->close();
  $outh->close();
  return $out;
}

my @checkers1 = ();
my $in = <<'INI';
hoge=huge
[aa]
bb=cc
INI
is(&up_test($in,["hoge=aaa"]),<<'OUT');
hoge=aaa
[aa]
bb=cc
OUT
is($in,&up_test($in,["[]"]),"何もしない");

is(&up_test($in,["[aa]","bb=aaa"]),<<'OUT');
hoge=huge
[aa]
bb=aaa
OUT
is(&up_test($in,["[aa]","bbc=aaa"]),<<'OUT');
hoge=huge
[aa]
bb=cc
bbc=aaa
OUT

is(&up_test($in,["bbc=aaa"]),<<'OUT');
hoge=huge
bbc=aaa
[aa]
bb=cc
OUT

is(&up_test($in,["[dd]","bbc=aaa"]),<<'OUT');
hoge=huge
[aa]
bb=cc
[dd]
bbc=aaa
OUT

