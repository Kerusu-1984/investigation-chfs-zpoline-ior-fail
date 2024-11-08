# CHFS via zpolineでIORが失敗する原因の調査
## 経緯
SCのポスター書くときに使っていた実験スクリプト([chfs-zpoline-separate-multinode.sh](https://github.com/Kerusu-1984/investigation-chfs-zpoline-ior-fail/blob/main/scripts/chfs-zpoline-separate-multinode.sh))が動かなくなってしまった。
9/18までは動いていたようだが、9/19からエラーが出るようになった。
