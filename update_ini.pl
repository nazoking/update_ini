package update_ini;
use strict;
use warnings;
use IO::File;

{
  package update_ini::checker;
  sub new{
    my $c = shift;
    my $data = {
      done => 0,
      in_section => 0,
      section=>shift,
      name=>shift,
      value=>shift
    };
    bless( $data,$c );
    return $data;
  }
  sub is_section {
    my $c = shift;
    my $section = shift;
    if( defined($c->{section}) ){
      return 0 unless defined( $section );
      return $c->{section} eq $section;
    }else{
      return ! defined( $section );
    }
  }
  sub is_name {
    my $c = shift;
    my $name = shift;
    return $c->{name} eq $name;
  }
  sub is{
    my $c = shift;
    my ($section,$name)=@_;
    return $c->is_section($section) && $c->is_name( $name );
  }
  sub done{
    my $c = shift;
    $c->{done}=1;
  }
};
sub parse_checkers{
  my $checkers = [];
  my $section = undef;
  my $data =  shift;
  my $skip_error =  shift;
  foreach my $a ( @$data ){
    if( $a =~ /^\[(.*?)\]/ ){
      $section = $1;
    }elsif( $a =~ /^(.*?)=(.*)$/ ){
      foreach my $c ( @$checkers ){
        if( $c->is($section,$1) ){
          die "同じ名前に対する書き換え指示が二重にあります $a";
        }
      }
      push @$checkers, update_ini::checker->new($section,$1,$2);
    }else{ 
      if( !$skip_error ){
        die "認識出来ない形式の引数 $a\n";
      }
    }
  }
  return $checkers;
}
sub read_checkers{
  my $options = shift;
  my $checkers;
  if( defined($options->{inputfile})){
    my $f = IO::File->new();
    if($options->{inputfile} eq "-"){
      $f->open(fileno(STDIN),"r");
    }else{
      $f->open($options->{inputfile},"r");
    }
    my @lines = $f->getlines;
    $f->close();
    $checkers = &parse_checkers( \@lines , 1 );
  }else{
    $checkers = &parse_checkers( $options->{inputs}, 0 );
  }
  return $checkers;
}
sub parse_args{
  my $a = shift;
  my %options = ();
  while(my $u=shift @$a){
    if($u eq "--input"){
      $options{"inputfile"}=shift @$a;
    }elsif( $u eq "--no-backup" ){
      $options{"no-backup"}=1;
    }else{
      $options{"loadfile"}=$u;
      $options{"inputs"}=$a;
      last;
    }
  }
  if( !defined($options{"loadfile"})){
    die "書き換えファイル名が見つかりません\n";
  }
  return \%options;
}
sub read_ini{
  my $options = shift;
  my $loadfile = $options->{loadfile};
  if( !-f $loadfile ){
    die "ファイルが存在しない $loadfile\n";
  }
  my $in = IO::File->new( $loadfile, "r" );
  my @ini = $in->getlines;
  $in->close;
  return \@ini;
}
sub write_backup{
  my $options = shift;
  my $loadfile = $options->{loadfile};
  my $backupname = $loadfile.".bak";
  for(my $i=1;-f $backupname;$i++){
    $backupname = $loadfile.".bak.$i";
  }
  use File::Copy 'copy';
  if(!copy($loadfile,$backupname)){
    die "バックアップの作成に失敗しました";
  }
}
sub update{
  my $options = shift;
  my $checkers = shift;
  my $ini = shift;
  my $out = shift;
  my $br="\n";
  foreach my $c ( @$checkers ){
    $c->{in_section} = 1 unless defined($c->{section});
  }
  foreach my $line (@$ini){
    if($line =~ /(\r?\n?)$/){
      $br = $1;
    }
    if($line =~ /^\[(.*)\]/){
      my ( $section ) = ( $1 );
      foreach my $c ( @$checkers ){
        if( !$c->{done} ){
          if( $c->{in_section} ){
            $out->print( "$c->{name}=$c->{value}$br" );
            $c->done;
          }elsif( $c->is_section($section) ){
            $c->{in_section} = 1;
          }
        }
      }
    }elsif( $line =~ /^(([^=]+)\s*=\s*)(.*)$/ ){
      my ($name,$front )=( $2,$1 );
      foreach my $c ( @$checkers ){
        if( $c->{in_section} && $c->is_name($name) ){
          $line=$front.$c->{value}.$br;
          $c->{done} = 1;
        }
      }
    }
    $out->print( $line );
  }
  foreach my $c ( @$checkers ){
    if( !$c->{done} && $c->{in_section} ){
      $out->print( "$c->{name}=$c->{value}$br" );
      $c->{done} = 1;
    }
  }

  foreach my $c ( @$checkers ){
    if( !$c->{done} ){
      $out->print( "[$c->{section}]$br" );
      $out->print( "$c->{name}=$c->{value}$br" );
      $c->{done} = 1;
      foreach my $d ( @$checkers ){
        if( !$d->{done} && $d->is_section( $c->{section} ) ){
          $out->print( "$d->{name}=$d->{value}$br" );
          $c->{done} = 1;
        }
      }
    }
  }
}
sub usage{
  print <<'___USAGE___';
update-ini.pl [オプション] filename 書き換え指示引数
  ini ファイル形式のファイルを書き換えます。

    ファイル filename を読み込み、書き換え指示引数に従って内容を書き換えます。
  
  書き換え指示引数
    "[section]" か "name=value" で指定します。

    example:
      update-ini.pl hoge.ini [section1] name1=value2 name2=value2 [section2] name1=value1

    "name=value" が ini ファイルの内部にあった場合、値をvalueにします。
    "[section]" が指定されたあとの "name=value" は、 iniファイルで同名のセクションが
    内のものに合致します。セクション内に合致する name= の値が無い場合はセクションの最後に
    追記されます。
    "[section]" が指定される前の "name=value" は、iniファイルでセクションが
    最初に出てくる前のものと合致し、同様の動きをします。
    
  オプション
    --no-backup
      バックアップを作成しません。通常、書き換え前の内容を、filenameに ".bak" を付け足した
      バックアップファイルに書き出します。
    --input filename2
      書き換え指示引数を filename2 から入力します。
      filename2 を "-" にすると標準入力から得ます

___USAGE___
}
sub main{
  my $options = &parse_args( $_[0] );
  my $checkers = &read_checkers($options);
  my $ini = &read_ini( $options );
  if(!defined($options->{"no-backup"})){
    &write_backup( $options, $ini );
  }
  my $out = IO::File->new($options->{loadfile},"w");
  &update( $options, $checkers, $ini, $out );
  $out->close;
}
if( __FILE__ eq $0 ){
  eval{
    &main( \@ARGV );
  };
  if( $@ ){
    &usage();
    die $@;
  }
}else{
  1;
}

