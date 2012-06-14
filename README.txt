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

