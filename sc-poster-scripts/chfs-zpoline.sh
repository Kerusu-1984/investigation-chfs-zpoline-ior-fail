#!/bin/bash

#PBS -A NBB
#PBS -q gpu
#PBS -T openmpi
#PBS -b 1
#PBS -l elapstim_req=00:30:00
#PBS -v NQSV_MPI_VER=4.1.6/gcc11.4.0-cuda12.3.2
#PBS -v USE_DEVDAX=pmemkv
#PBS -v NUM_DEVDAX=1

module load openmpi/4.1.6/gcc11.4.0-cuda12.3.2

. /work/NBB/miyauchi/try-chfs/spack/share/spack/setup-env.sh
spack env activate chfs

export LD_LIBRARY_PATH=/work/NBB/miyauchi/try-chfs/spack/var/spack/environments/chfs2/.spack-env/view/lib:/work/NBB/miyauchi/try-chfs/spack/var/spack/environments/chfs3/.spack-env/view/lib
export PATH=/work/NBB/miyauchi/try-chfs/ior/build/bin:$PATH:/work/NBB/miyauchi/try-chfs/spack/var/spack/environments/chfs2/.spack-env/view/sbin


_CHFS_CHUNK_SIZE=$((1024*1024*4))
_CHFS_DB_SIZE=$((1024*1024*1024*1536))
_CHFS_NTHREADS=16

export CHFS_CHUNK_SIZE=$_CHFS_CHUNK_SIZE
export CHFS_ASYNC_ACCESS=1

MPIENVS="-x PATH -x LD_LIBRARY_PATH -x PYTHONPATH -x CHFS_CHUNK_SIZE -x CHFS_SERVER -x CHFS_BUF_SIZE -x CHFS_ASYNC_ACCESS"
export CHFS_SERVER=""

CHFS_INIT=0
for node in `cat ${NQSII_MPINODES} | awk '{print $1}'`; do
        MPIRUN="mpirun -H $node $MPIENVS -np 1 -bind-to none"
    echo "[$node] chfs setup start"
        if [ $CHFS_INIT -eq 0 ]; then
                eval `eval "${MPIRUN} chfsctl start -c /dev/dax0.0 -D -p verbs -s ${_CHFS_DB_SIZE}    -C 0 -I mlx5_0 -NUMACTL \"--physcpubind 32-47\" -O \"-T $_CHFS_NTHREADS\""`
        else
                eval `eval "${MPIRUN} chfsctl start -c /dev/dax0.0 -D -p verbs -s ${_CHFS_DB_SIZE} -A -C 0 -I mlx5_0 -NUMACTL \"--physcpubind 32-47\" -O \"-T $_CHFS_NTHREADS\""`
        fi
        echo "[$node] chfs setup done"
        CHFS_INIT=1
done


IORPPN=1

NUMNODES=`cat ${NQSII_MPINODES} | wc -l`

mpirun --np $((NUMNODES))  ${NQSII_MPIOPTS} --map-by node sudo sysctl vm.mmap_min_addr=0

export LIBZPHOOK=/work/NBB/miyauchi/try-chfs/chfs-zpoline/build/lib/libcz.so

cd /work/NBB/miyauchi/try-chfs/cz


mpirun --report-bindings --np $((IORPPN*NUMNODES)) ${NQSII_MPIOPTS}  $MPIENVS -x LIBZPHOOK -x LD_PRELOAD=/work/NBB/miyauchi/try-chfs/chfs-zpoline/build/lib/libzpoline.so --map-by ppr:$IORPPN:socket:PE=1 ior -C -t 4194304 -b 1099511627776 -F -w -a POSIX -Q 1 -g -k -e -o /chfs/ior_file_easy --dataPacketType=timestamp -G -1386302275 -O summaryFormat=json > $PBS_JOBID.write.json

mpirun --report-bindings --np $((IORPPN*NUMNODES)) ${NQSII_MPIOPTS}  $MPIENVS -x LIBZPHOOK -x LD_PRELOAD=/work/NBB/miyauchi/try-chfs/chfs-zpoline/build/lib/libzpoline.so --map-by ppr:$IORPPN:socket:PE=1 ior -C -t 4194304 -b 1099511627776 -F -r -a POSIX -Q 1 -g  -k -e -o /chfs/ior_file_easy --dataPacketType=timestamp -G -1386302275 -O summaryFormat=json > $PBS_JOBID.read.json
