import glob
import os
from pathlib import Path

def get_sample_option(wc):
    option_str=""
    prefix=units["sample"][wc.sample] 
    option_str += f"--sample={prefix}"
    return option_str

rule samples_csv:
    output:
        csv = "{}/{{sample}}/cellranger_count/samples.csv".format(OUTDIR)
    params:
        outdir = OUTDIR,
        sample = lambda wc: units["sample"][wc.sample]
    threads:
        get_resource("default", "threads")
    resources:
        mem_mb=get_resource("default", "mem_mb"),
        walltime=get_resource("default", "walltime")
    log:
        err="{}/{{sample}}/samples_csv.err".format(LOGDIR),
        out="{}/{{sample}}/samples_csv.out".format(LOGDIR),
        time="{}/{{sample}}/samples_csv.time".format(LOGDIR)
    script:
        "../scripts/create_samples_csv.R"

rule cellranger_count:
    input:
        fq=lambda wc: units["fqs"][wc.sample],
        csv = "{}/{{sample}}/cellranger_count/samples.csv".format(OUTDIR)
    output:
        finish="{}/{{sample}}/cellranger_count/cellranger.finish".format(OUTDIR)
    params:    
        reference=config['cellranger']['reference']
    envmodules:
        config['envmodules']['cellranger']
    threads: get_resource("cellranger", "threads")
    resources:
        mem_mb=get_resource("cellranger", "mem_mb"),
        walltime=get_resource("cellranger", "walltime")
    log:
        err="{}/{{sample}}/cellranger.err".format(LOGDIR),
        out="{}/{{sample}}/cellranger.out".format(LOGDIR),
        time="{}/{{sample}}/cellranger.time".format(LOGDIR)
    shell:
        """
        {DATETIME} > {log.time} &&
        cellranger-arc count --id={wildcards.sample} \
        --reference={params.reference} \
        --libraries={input.csv} 2> {log.err} > {log.out}
        mv {wildcards.sample}/* {OUTDIR}/{wildcards.sample}/cellranger_count
        rm -rf {OUTDIR}/{wildcards.sample}/cellranger_count/_*
        rm -rf {OUTDIR}/{wildcards.sample}/cellranger_count/*mri.tgz
        rm -rf {OUTDIR}/{wildcards.sample}/cellranger_count/SC_ATAC_GEX_COUNTER_CS
        rm -rf {OUTDIR}/{wildcards.sample}/cellranger_count/outs/analysis
        rm -rf {OUTDIR}/{wildcards.sample}/cellranger_count/outs/cloupe.cloupe
        touch {OUTDIR}/{wildcards.sample}/cellranger_count/cellranger.finish
        rm -rf {wildcards.sample}
        {DATETIME} >> {log.time} 
        """
