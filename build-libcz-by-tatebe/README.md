建部先生がビルドしたlibczを使用したスクリプト群とその実行結果

- zpoline.sh
  
    建部先生が動かしたスクリプトの、libczやlibzpolineのパスを絶対パスに変更したもの

`zpoline.sh`は宮内がポスターで示した性能よりなぜか遅くなる

chfsやiorを宮内が使用していたものに変更することで性能が変化するのではないか？と考え、以下のスクリプトを作成

- zpoline-tatebe-chfs-miyauchi.sh
  
    libczやlibzpoline、libopcodes等のライブラリは建部先生がビルドしたもの、chfsやiorは宮内がインストールしたもの
  
    ポスターほどではないが性能の向上が見られた

- zpoline-ior-tatebe-chfs-miyauchi.sh
  
    chfsだけ宮内がspackでインストールしたもの、それ以外のバイナリやライブラリは建部先生がビルドしたもの
  
    `zpoline-tatebe-chfs-miyauchi.sh`と同じ性能なので、iorは無罪

-  zpoline-chfs-tatebe-ior-miyauchi.sh
  
    iorだけ宮内がgithub経由でインストールしたもの、それ以外のバイナリやライブラリは建部先生がビルドしたもの
   
    `zpoline.sh`と同じく性能が低下したため、宮内がspackでインストールしたchfsと建部先生がビルドしたchfsに違いがある？
