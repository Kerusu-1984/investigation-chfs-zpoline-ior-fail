ポスター書いているときに用意していたスクリプト群　
- chfs-zpoline-separate-multinode.sh(現在は動かない)
    - chfsサーバとクライアントを分離して動かすスクリプト
- chfs-zpoline.sh(現在は動かない)
    - chfsサーバとクライアントを同一ノードで動かすスクリプト
    - IORPPNを2以上にすると動かない
- chfs-native.sh(現在も動く)
    - libczを使わずに、CHFSのAPIを利用してIORを動かすスクリプト