package update_ini;
use strict;
use warnings;
use Test::More tests=>3;# qw(no_plan);
use IO::File;
use FindBin;
use Data::Dumper;
require $FindBin::Bin.'/../update_ini.pl';
use File::Temp;
sub read{
  my $f = shift;
  local $/ = undef;
  open H, $f;
  my $ret = <H>;
  close H;
  return $ret
}
my $dir = File::Temp::tempdir;
my $f = File::Temp->new( $dir );

my $org = <<'INI';
[aa]
ww=oo
# no change
xx=yy
INI
$f->print($org);
$f->flush;
ok(!-f $f->filename.".bak");
&main( [$f->filename, "[aa]", "xx=zz", "yy=cc"] );
is( &read($f->filename), <<'INI');
[aa]
ww=oo
# no change
xx=zz
yy=cc
INI
is( &read($f->filename.".bak"), $org);


