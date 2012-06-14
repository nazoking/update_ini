#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use IO::File;
require $FindBin::Bin.'/../update_ini.pl';
package update_ini;
use Test::More qw(no_plan);

my $c = update_ini::checker->new("hoge","huge","vv");
my $d = update_ini::checker->new(undef,"huge","vv");
ok($c->is_section("hoge"));
ok(!$c->is_section(undef));
ok($c->is_name("huge"));
ok($c->is("hoge","huge"));
ok(!$d->is_section("hoge"));
ok($d->is_section(undef));
ok($d->is_name("huge"));
ok(!$d->is("hoge","huge"));
ok($d->is(undef,"huge"));

