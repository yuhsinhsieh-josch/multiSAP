import glob
import os
import pandas as pd

# -- Auxiliar functions -- #
def fastq_input(wc):
    directory=units.loc[wc.sample]['fqs']
    return [os.path.join(directory, file) for file in os.listdir(directory)]

def get_fastq_dir(wc):
    directory=units.loc[wc.sample]['fqs']
    return directory

def get_fastq_ATAC(wc):
    # Get the directory specific to the current sample
    directory=units.loc[wc.sample]['fqs'] + "/ATAC"
    # Ensure the file pattern is scoped to the current sample
    s = wc.sample + "_"
    # List files in the directory and filter those matching the sample pattern
    files = os.listdir(directory)
    samples = [file.split(s)[1].split('.fastq.gz')[0] for file in files if re.match(s, file)]
    # Print for debugging purposes to ensure correct files are being picked up
    return list(set(samples))   # Return unique samples

def get_fastq_GEX(wc):
     directory=units.loc[wc.sample]['fqs'] + "/GEX"
     s = wc.sample + "_"
     samples = [file.split(s)[1].split('.fastq.gz')[0] for file in os.listdir(directory) if re.match(s, file)]
     return list(set(samples))

# -- Rules -- #
rule fastqc_GEX:
    input:
        fq=lambda wc: expand("{DIR}/{library_type}/{{sample}}_{library_type}_{{name_GEX}}.fastq.gz", DIR = units.loc[wc.sample]['fqs'], library_type = ['GEX'])
    output:
        html=expand("{OUTDIR}/{{sample}}/qc/fastqc/{{sample}}_{library_type}_{{name_GEX}}_fastqc.html", OUTDIR=OUTDIR, library_type = ['GEX']),
        zip=expand("{OUTDIR}/{{sample}}/qc/fastqc/{{sample}}_{library_type}_{{name_GEX}}_fastqc.zip", OUTDIR=OUTDIR, library_type = ['GEX'])
    params:
        lambda wc: "-t {}".format(get_resource("fastqc","threads")) 
    resources:
        mem_mb=get_resource("fastqc", "mem_mb"),
        walltime=get_resource("fastqc", "walltime")
    log:
        "{}/{{sample}}/fastqc_{{sample}}_{{name_GEX}}.log".format(LOGDIR)
    benchmark:
        "{}/{{sample}}/fastqc_{{sample}}_{{name_GEX}}.bmk".format(LOGDIR)
    threads: 
        threads=get_resource("fastqc", "threads")
    wrapper:
        "v4.7.3/bio/fastqc"

rule fastqc_ATAC:
    input:
        fq= lambda wc: expand("{DIR}/{library_type}/{{sample}}_{library_type}_{{name_ATAC}}.fastq.gz", DIR = units.loc[wc.sample]['fqs'], library_type = ['ATAC'])
    output:
        html=expand("{OUTDIR}/{{sample}}/qc/fastqc/{{sample}}_{library_type}_{{name_ATAC}}_fastqc.html", OUTDIR=OUTDIR, library_type = ['ATAC']),
        zip=expand("{OUTDIR}/{{sample}}/qc/fastqc/{{sample}}_{library_type}_{{name_ATAC}}_fastqc.zip", OUTDIR=OUTDIR, library_type = ['ATAC'])
    params:
        lambda wc: "-t {}".format(get_resource("fastqc","threads")) 
    resources:
        mem_mb=get_resource("fastqc", "mem_mb"),
        walltime=get_resource("fastqc", "walltime")
    log:
        "{}/{{sample}}/fastqc_{{sample}}_{{name_ATAC}}.log".format(LOGDIR)
    benchmark:
        "{}/{{sample}}/fastqc_{{sample}}_{{name_ATAC}}.bmk".format(LOGDIR)
    threads: 
        threads=get_resource("fastqc", "threads")
    wrapper:
        "v4.7.3/bio/fastqc"

rule fastq_screen_indexes:
    output:
        "resources/FastQ_Screen_Genomes/fastq_screen.conf"
    log:
        "{}/fastq_screen_idx.log".format(LOGDIR)
    benchmark:
        "{}/fastq_screen_idx.bmk".format(LOGDIR)
    conda:
        "envs/fastq_screen.yaml"
    threads: get_resource("fastq_screen", "threads")
    params:
        outdir=config["fastq_screen"]["index_dir"]
    resources:
        mem_mb=get_resource("fastq_screen", "mem_mb"),
        walltime=get_resource("fastq_screen", "walltime")
    shell:
        """
        fastq_screen --threads {threads} --get_genomes --outdir{params.outdir} /
        &> {log}
        """

rule fastq_screen:
    input:
        fq=lambda wc: expand("{DIR}/{{sample}}/qc/fastqc/{{sample}}_{{name}}_fastqc.html", DIR = units.loc[wc.sample]['fqs']),
        conf="{}/FastQ_Screen_Genomes/fastq_screen.conf".format(config["fastq_screen"]["index_dir"])
    output:
        txt=expand("{OUTDIR}/{{sample}}/qc/fastq_screen/{{sample}}_{{name}}.fastq_screen.txt", OUTDIR=OUTDIR),
        png=expand("{OUTDIR}/{{sample}}/qc/fastq_screen/{{sample}}_{{name}}.fastq_screen.png", OUTDIR=OUTDIR)
    log:
        "{}/{{sample}}/fastq_screen_{{sample}}_{{name}}.log".format(LOGDIR)
    benchmark:
        "{}/{{sample}}/fastq_screen_{{sample}}_{{name}}.bmk".format(LOGDIR)
    threads: get_resource("fastq_screen","threads")
    resources:
        mem_mb=get_resource("fastq_screen","mem_mb"),
        walltime=get_resource("fastq_screen","walltime")
    params:
        fastq_screen_config="{}/FastQ_Screen_Genomes/fastq_screen.conf".format(config["fastq_screen"]["index_dir"]),
        subset=100000,
        aligner='bowtie2'
    wrapper:
        "v1.23.4/bio/fastq_screen"


def multiqc_input(wc):
    # Get ATAC and GEX names for the current sample
    name_ATAC = get_fastq_ATAC(wc)
    name_GEX = get_fastq_GEX(wc)
    # Use expand to generate the input files for both ATAC and GEX
    f=expand("{OUTDIR}/{sample}/qc/fastqc/{sample}_{name_ATAC}_fastqc.zip", OUTDIR=OUTDIR, sample = wc.sample, name_ATAC = name_ATAC)
    f+=expand("{OUTDIR}/{sample}/qc/fastqc/{sample}_{name_GEX}_fastqc.zip", OUTDIR=OUTDIR, sample = wc.sample, name_GEX = name_GEX) 
    try: 
        if config["parameters"]["fastq_screen"]["enabled"]:
            f +=expand("{OUTDIR}/{sample}/qc/fastq_screen/{sample}.{name_ATAC}.fastq_screen.txt", OUTDIR=OUTDIR, sample = wc.sample, name_ATAC=name_ATAC)
            f +=expand("{OUTDIR}/{sample}/qc/fastq_screen/{sample}.{name_GEX}.fastq_screen.txt", OUTDIR=OUTDIR, sample = wc.sample, name_GEX=name_GEX)
    except KeyError:
        print("FASTQ_SCREEN disabled by config file. Skipping...")
    return f

rule multiqc:
    input:
        multiqc_input,
    output:
        report(f"{OUTDIR}/{{sample}}/qc/multiqc_report.html", category="1_QC")
    params: 
        config["multiqc"]
    benchmark:
        "{}/{{sample}}/multiqc.bmk".format(LOGDIR)
    log:
        "{}/{{sample}}/multiqc.log".format(LOGDIR)
    threads: get_resource("multiqc", "threads")
    resources:
        mem_mb=get_resource("multiqc","mem_mb"),
        walltime=get_resource("multiqc","walltime")
    wrapper:
        "v4.7.3/bio/multiqc"
