import glob

rule zcat:
    input:
        finish="{}/{{sample}}/cellranger_count/cellranger.finish".format(OUTDIR)
    output:
        tsv="{}/{{sample}}/cellranger_count/outs/filtered_feature_bc_matrix/barcodes.tsv".format(OUTDIR)
    params: 
         gz="{}/{{sample}}/cellranger_count/outs/filtered_feature_bc_matrix/barcodes.tsv.gz".format(OUTDIR)
    threads: get_resource("default", "threads")
    resources:
        mem_mb=get_resource("default", "mem_mb"),
        walltime=get_resource("default","walltime")
    log:
        err="{}/{{sample}}/zcat.err".format(LOGDIR),
        out="{}/{{sample}}/zcat.out".format(LOGDIR)
    shell: 
        """
        zcat -k {params.gz} > {output.tsv}
        """

rule mgatk:
    input:
        tsv="{}/{{sample}}/cellranger_count/outs/filtered_feature_bc_matrix/barcodes.tsv".format(OUTDIR)
    params:
        bam="{}/{{sample}}/cellranger_count/outs/atac_possorted_bam.bam".format(OUTDIR)
    output:
        ref="{}/{{sample}}/mgatk/final/mgatk.rds".format(OUTDIR)
    conda:
        "../envs/mgatk.yaml"
    threads: get_resource("mgatk", "threads")
    resources:
        mem_mb=get_resource("mgatk", "mem_mb"),
        walltime=get_resource("mgatk", "walltime")
    log:
        err="{}/{{sample}}/mgatk.err".format(LOGDIR),
        out="{}/{{sample}}/mgatk.out".format(LOGDIR)
    shell:
        """
        cd {OUTDIR}/{wildcards.sample}
        # common error resolved by those two export commands
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
        # run mgatk command
        mgatk tenx -i {params.bam}  -o {OUTDIR}/{wildcards.sample}/mgatk -bt CB -b {input.tsv} 
        """
