import pandas as pd
import os

# -- Snakefile basic configuration -- #
report: "report/workflow.rst"
# Include rule files
include: "rules/common.smk"
# Variable declaration
OUTDIR = config["out"]
LOGDIR = config["log"]

# -- Read samples file -- #
try:
    samples = pd.read_csv(config["samples"], sep="\t", comment="#").set_index("sample", drop=False)
    validate(samples, schema="schemas/samples.schema.yaml")
except FileNotFoundError:
    warning(f"ERROR: the samples file ({config['samples']}) does not exist. Please see the README file for details. Quitting now.")
    sys.exit(1)

# -- Read units file -- #
try:
    units = pd.read_csv(config["units"], dtype=str, sep="\t", comment="#").set_index(["sample"], drop=False)
    validate(units, schema="schemas/units.schema.yaml")
except FileNotFoundError:
    warning(f"ERROR: the units file ({config['units']}) does not exist. Please see the README file for details. Quitting now.")
    sys.exit(1)    

# -- Auxiliary functions -- #
def get_resource(rule,resource):
    try:
        return config["resources"][rule][resource]
    except KeyError:
        return config["resources"]["default"][resource]

def get_integration_outs(wc):
    file = expand("{OUTDIR}/{sample}/cellranger_count/outs/", sample = samples['sample'],OUTDIR=OUTDIR)
    file = list(set(file))
    return file

def get_integration_mgatk(wc):
    file = expand("{OUTDIR}/{sample}/mgatk/final/", sample = samples['sample'],OUTDIR=OUTDIR)
    file = list(set(file))
    return file

def get_integration_amulet(wc):
    file = expand("{OUTDIR}/{sample}/amulet/MultipletBarcodes_01.txt", sample = samples['sample'],OUTDIR=OUTDIR)
    file = list(set(file))
    return file

# Create a rule that decides whether an integrated or merged object could be
# the output. For instance: if harmony = TRUE and exists a merged.rds file;
# then the output is mergedintegration.rds

# -- Final output -- #
rule all:
    input:
        expand(["{OUTDIR}/{sample}/cellranger_count/cellranger.finish",
                # "{OUTDIR}/{sample}/qc/multiqc_report.html",
                "{OUTDIR}/{sample}/mgatk/final/mgatk.rds",
                "{OUTDIR}/{sample}/amulet/MultipletBarcodes_01.txt",
                "{OUTDIR}/{sample}/cellbender/cellbender_output_file.h5",
                "{OUTDIR}/{sample}/signac/01_preprocessing_{sample}.html"
                ], sample=samples['sample'], OUTDIR=OUTDIR)

# -- Rule files -- #
include: "rules/cellranger.smk"
#include: "rules/qc.smk"
include: "rules/mgatk.smk"
include: "rules/amulet.smk"
include: "rules/signac.smk"
include: "rules/cellbender.smk"
