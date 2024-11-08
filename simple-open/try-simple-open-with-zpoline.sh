#!/bin/bash

#PBS -A NBB
#PBS -q gpu
#PBS -b 4
#PBS -T openmpi
#PBS -v NQSV_MPI_VER=4.1.6/gcc11.4.0-cuda12.3.2
#PBS -l elapstim_req=01:00:00
#PBS -v USE_DEVDAX=pmemkv
#PBS -v NUM_DEVDAX=1

module load openmpi/$NQSV_MPI_VER
cd $PBS_O_WORKDIR

. /work/NBB/miyauchi/try-chfs/spack/share/spack/setup-env.sh
spack env activate chfs2

export LD_LIBRARY_PATH=/work/NBB/miyauchi/try-chfs/spack/var/spack/environments/chfs3/.spack-env/view/lib:$LD_LIBRARY_PATH

TMPDIR=/dev/dax0.0
clients=1
nnodes=$(wc -l $PBS_NODEFILE | awk '{ print $1 }')

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
_CHFS_CHUNK_SIZE=$((1024*1024*16))

export CHFS_ASYNC_ACCESS=1
export CHFS_RPC_TIMEOUT_MSEC=0
export CHFS_CHUNK_SIZE=$_CHFS_CHUNK_SIZE
eval `chfsctl -p verbs -D -s ${_CHFS_DB_SIZE} -h $THOST -c $TMPDIR -L $LOGD -O "-H 0 -T 46" start`

chfsctl -h $THOST status
chlist
echo $CHFS_SERVER > $CDIR/chfs_server-$$

sudo sysctl vm.mmap_min_addr=0

export LIBZPHOOK=/work/NBB/miyauchi/try-chfs/chfs-zpoline-git/.libs/libcz.so

# open.cをコンパイルしたパス
open="/work/NBB/miyauchi/try-chfs/investigation-fail-ior-assert/open"
LD_PRELOAD=/work/NBB/miyauchi/try-chfs/chfs-zpoline-git/zpoline/libzpoline.so $open