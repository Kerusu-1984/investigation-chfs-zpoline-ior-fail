#!/bin/bash

#PBS -A NBB
#PBS -q gpu
#PBS -b 11
#PBS -T openmpi
#PBS -v NQSV_MPI_VER=4.1.6/gcc11.4.0-cuda12.3.2
#PBS -l elapstim_req=01:00:00
#PBS -v PPN=2
#PBS -v USE_DEVDAX=pmemkv

module load openmpi/$NQSV_MPI_VER
cd $PBS_O_WORKDIR


tatebe_zpoline=/work/0/NBB/tatebe/zpoline
export PATH=$tatebe_zpoline/bin:$PATH

TMPDIR=/dev/dax0.0
clients=1
nnodes=$(wc -l $PBS_NODEFILE | awk '{ print $1 }')
nprocs=$((PPN * clients))

CDIR=$PBS_O_WORKDIR/cdir-zpoline-$PPN-$$
LOGD=$CDIR/log
mkdir -p $LOGD

export THOST=$CDIR/host-$$
export CHOST=$CDIR/chost-$$
export MPIHOST=$CDIR/mpihost-$$

tail -n $((nnodes - clients)) $PBS_NODEFILE > $THOST
head -n $clients $PBS_NODEFILE > $CHOST
head -n $clients $NQSII_MPINODES > $MPIHOST

export CHFS_ASYNC_ACCESS=1
export CHFS_RPC_TIMEOUT_MSEC=0
export CHFS_CHUNK_SIZE=$((4 * 1024 * 1024))

eval `chfsctl -p verbs -D -h $THOST -c $TMPDIR -L $LOGD -O "-H 0 -T 46" start`

chfsctl -A -h $THOST status > $CDIR/chfs_status-$$
chlist > $CDIR/chfs_list-$$
echo $CHFS_SERVER > $CDIR/chfs_server-$$

export LD_LIBRARY_PATH=/work/0/NBB/tatebe/git/spack/opt/spack/linux-ubuntu22.04-sapphirerapids/gcc-11.4.0/binutils-2.42-jsphrnabh53j45er24kvafts2f2ebpyj/lib:/work/0/NBB/tatebe/git/spack/opt/spack/linux-ubuntu22.04-sapphirerapids/gcc-11.4.0/mochi-margo-0.17.0-dsk74rivnia5jroaeintwcosyzkmml3b/lib:$LD_LIBRARY_PATH
export LIBZPHOOK=$tatebe_zpoline/lib/libcz.so

MPIENVS="-x PATH"
MPIENVS="$MPIENVS -x CHFS_SERVER -x CHFS_CHUNK_SIZE -x CHFS_ASYNC_ACCESS -x CHFS_RPC_TIMEOUT_MSEC"
MPIENVS="$MPIENVS -x LD_LIBRARY_PATH -x LIBZPHOOK -x LD_PRELOAD=$tatebe_zpoline/lib/libzpoline.so"
MPIARGS="--leave-session-attached -hostfile $MPIHOST -np $nprocs -npernode $PPN"

sudo sysctl vm.mmap_min_addr=0

BSIZE=68719476736
#BSIZE=$((10 * CHFS_CHUNK_SIZE))
mpirun $MPIARGS $MPIENVS /work/NBB/miyauchi/try-chfs/ior/build/bin/ior -C -t $CHFS_CHUNK_SIZE -b $BSIZE -F \
	-a POSIX \
	-Q 1 -g -e -o /chfs/ior_file_easy --dataPacketType=timestamp \
	-G -1386302275 -O summaryFormat=json > zpoline-$PPN-$PBS_JOBID.json
