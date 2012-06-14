#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Data::Dumper;
require $FindBin::Bin.'/../update_ini.pl';
package update_ini;
use Test::More tests=>18;# qw(no_plan);
use File::Temp;

my $options = &parse_args( ["file", "namec=valuec", "[hoge]", "namev=valuev"] );
my $checkers = &read_checkers( $options );
is( $options->{loadfile} , "file" );
ok( !defined(@$checkers[0]->{section}) );
is( @$checkers[0]->{name} , "namec" );
is( @$checkers[0]->{value} , "valuec" );
is( @$checkers[1]->{section} , "hoge" );
is( @$checkers[1]->{name} , "namev" );
is( @$checkers[1]->{value} , "valuev" );

eval{
  &parse_args( [] );
};
ok($@,"引数がないときはエラーを吐く $@");

eval{
  &read_checkers( &parse_args( ["file", "[section]", "namec=valuec", "namec=valuec"] ) );
};
ok($@,"同じ値の書き換えはエラー $@");
eval{
  &read_checkers( &parse_args( ["file", "namec=valuec", "namec=valuec"] ) );
};
ok($@,"同じ値の書き換えはエラー $@");
eval{
  &read_checkers( &parse_args( ["file", "[section]", "namec=valuec", "[section]", "namec=valuec"] ) );
};
ok($@,"同じ値の書き換えはエラー $@");

{
  my $f =File::Temp->new;
  $f->print(<<'INI');
namec=valuec
[hoge]
namev=valuev
INI
  $f->flush;
  my $options = &parse_args( ["--input",$f->filename,"file"] );
my $checkers = &read_checkers( $options );
is( $options->{loadfile} , "file" );
ok( !defined(@$checkers[0]->{section}) );
is( @$checkers[0]->{name} , "namec" );
is( @$checkers[0]->{value} , "valuec" );
is( @$checkers[1]->{section} , "hoge" );
is( @$checkers[1]->{name} , "namev" );
is( @$checkers[1]->{value} , "valuev" );
}
