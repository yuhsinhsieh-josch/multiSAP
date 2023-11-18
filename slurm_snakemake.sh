#!/bin/bash
#SBATCH --job-name=multiSAP
#SBATCH --output=/data/gpfs-1/projects/ludwig-multimito/work/logs/%x-%j.log
#SBATCH --ntasks=2
#SBATCH --nodes=1
#SBATCH --mem=4G
#SBATCH --partition=medium
#SBATCH --time=7-00:00:00


export TMPDIR=/fast/users/${USER}/scratch/tmp
set -x

snakemake --use-conda --use-envmodules --jobs 10 --profile hpc-cluster -k -p
# snakemake --use-conda --conda-create-envs-only --conda-frontend mamba --profile cubi-v1
