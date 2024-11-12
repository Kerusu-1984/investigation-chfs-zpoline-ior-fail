建部先生がビルドしたlibczを使用したスクリプト群とその実行結果

- zpoline.sh
建部先生が動かしたスクリプトの、libczやlibzpolineのパスだけ変更したもの

宮内がポスターで示した性能よりなぜか遅くなるので、以下のスクリプトを作成して調査

- zpoline-tatebe-chfs-miyauchi.sh
    libczやlibzpoline,libopcodes等のライブラリは建部先生がビルドしたもの、chfsやiorは宮内がインストールしたもの 
    ポスターほどではないが性能の向上が見られた

- zpoline-ior-tatebe-chfs-miyauchi.sh
    chfsだけ宮内がspackでインストールしたもの、zpoline-tatebe-chfs-miyauchi.shのiorを建部先生がビルドしたものに変更 
    zpoline-tatebe-chfs-miyauchi.shと同じ性能なので、iorは無罪

-  zpoline-chfs-tatebe-ior-miyauchi.sh
    iorだけ宮内がgithub経由でインストールしたもの、zpoline-tatebe-chfs-miyauchi.shのchfsを建部先生がビルドしたものに変更 
    zpoline.shと同じく性能が低下したため、宮内がspackでインストールしたchfsと建部先生がビルドしたchfsに違いがある？