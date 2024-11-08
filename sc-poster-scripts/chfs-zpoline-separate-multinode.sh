#!/bin/bash

#PBS -A NBB
#PBS -q gpu
#PBS -b 11
#PBS -T openmpi
#PBS -v NQSV_MPI_VER=4.1.6/gcc11.4.0-cuda12.3.2
#PBS -l elapstim_req=01:00:00
#PBS -v PPN=1
#PBS -v USE_DEVDAX=pmemkv
#PBS -v NUM_DEVDAX=1

module load openmpi/$NQSV_MPI_VER
cd $PBS_O_WORKDIR

# spackでCHFSをインストールした環境を用意し、有効にする必要がある。
# CHFSのインストールのオプション指定は chfs@master+devdax+pmemkv+verbs+zero_copy_read_rdma ^libfuse@2.9.9%gcc@11.4.0
. /work/NBB/miyauchi/try-chfs/spack/share/spack/setup-env.sh
spack env activate chfs2

# zpolineにlibopcodesというライブラリが必要なのだが、それが入っているbinutilsをchfs3という別の環境でインストールした。
export LD_LIBRARY_PATH=/work/NBB/miyauchi/try-chfs/spack/var/spack/environments/chfs3/.spack-env/view/lib:$LD_LIBRARY_PATH
export PATH=/work/NBB/miyauchi/try-chfs/ior/build/bin:$PATH
TMPDIR=/dev/dax0.0
clients=1
ppn=$PPN
nnodes=$(wc -l $PBS_NODEFILE | awk '{ print $1 }')
nprocs=$((ppn * clients))

CDIR=$PBS_O_WORKDIR/cz-separate/cdir-$nnodes-$$
LOGD=$CDIR/log
mkdir -p $LOGD

export THOST=$CDIR/host-$$
export CHOST=$CDIR/chost-$$
export MPIHOST=$CDIR/mpihost-$$

tail -n $((nnodes - clients)) $PBS_NODEFILE > $THOST
head -n $clients $PBS_NODEFILE > $CHOST
head -n $clients $NQSII_MPINODES > $MPIHOST

_CHFS_DB_SIZE=$((1024*1024*1024*1536))
# チャンクサイズは16MiBが一番性能が良かった
_CHFS_CHUNK_SIZE=$((1024*1024*16))

export CHFS_ASYNC_ACCESS=1
export CHFS_RPC_TIMEOUT_MSEC=0
export CHFS_CHUNK_SIZE=$_CHFS_CHUNK_SIZE
eval `chfsctl -p verbs -D -s ${_CHFS_DB_SIZE} -h $THOST -c $TMPDIR -L $LOGD -O "-H 0 -T 46" start`

chfsctl -h $THOST status
chlist
echo $CHFS_SERVER > $CDIR/chfs_server-$$

# LD_PRELOADの値はKerusu-1984/chfs-zpolineをクローンしたパスに置き換える
MPIENVS="-x PATH -x LD_LIBRARY_PATH -x PYTHONPATH -x CHFS_CHUNK_SIZE -x CHFS_SERVER -x CHFS_BUF_SIZE -x CHFS_ASYNC_ACCESS -x LIBZPHOOK -x LD_PRELOAD=/work/NBB/miyauchi/try-chfs/chfs-zpoline-git/zpoline/libzpoline.so"
MPIARGS="--leave-session-attached --report-bindings -hostfile $MPIHOST -np $nprocs -npernode $ppn"
# カレントディレクトリにIORの結果が出力される
cd /work/NBB/miyauchi/try-chfs/cz-separate

# zpolineを使うのに仮想メモリのアドレス0から使えるようにする必要がある
sudo sysctl vm.mmap_min_addr=0

# LD_PRELOADと同様
export LIBZPHOOK=/work/NBB/miyauchi/try-chfs/chfs-zpoline-git/.libs/libcz.so

# ブロックサイズ×プロセス数が永続メモリの容量2TiB(256GiB×8)を超えないようにする
mpirun $MPIARGS  $MPIENVS ior -C -t $CHFS_CHUNK_SIZE -b 68719476736 -F -a POSIX -Q 1 -i 5 -g -e -o /chfs/ior_file_easy --dataPacketType=timestamp  -G -1386302275 -O summaryFormat=json > $PBS_JOBID.json
