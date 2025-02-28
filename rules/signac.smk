import glob

if config["signac"]["enable"]:
    rule step1_preprocess:
        input:
            finish="{}/{{sample}}/cellranger_count/cellranger.finish".format(OUTDIR),
            ref="{}/{{sample}}/mgatk/final/mgatk.rds".format(OUTDIR),
            amulet="{}/{{sample}}/amulet/MultipletBarcodes_01.txt".format(OUTDIR)
        output:
            report="{}/{{sample}}/signac/01_preprocessing_{{sample}}.html".format(OUTDIR)
        conda:
            "../envs/signac.yaml"
        params: 
            outs="{}/{{sample}}/cellranger_count/outs/".format(OUTDIR),
            mgatk="{}/{{sample}}/mgatk/final".format(OUTDIR),
            amulet="{}/{{sample}}/amulet/MultipletBarcodes_01.txt".format(OUTDIR),
            directory = expand("{OUTDIR}/", OUTDIR = OUTDIR),
            reference = config['signac']['annotation']['reference'],
            haplogroup = config['signac']['annotation']['haplogroup'],
            ncount_rna_max = config['signac']['qc']['ncount_rna_max'],            
            ncount_atac_max = config['signac']['qc']['ncount_atac_max'],
            ncount_atac_min = config['signac']['qc']['ncount_atac_min'],
            ncount_rna_min=config['signac']['qc']['ncount_rna_min'],
            nuclesome_signal = config['signac']['qc']['nuclesome_signal'],
            tss_enrichment = config['signac']['qc']['tss_enrichment'],
            percent_mt = config['signac']['qc']['percent_mt'],
            min_depth = config['signac']['mito']['min_depth'],
            n_cells_conf_detected = config['signac']['mito']['n_cells_conf_detected'],
            strand_correlation = config['signac']['mito']['strand_correlation'],
            min_cell_var = config['signac']['mito']['min_cell_var']
        threads: get_resource("signac", "threads")
        resources:
            mem_mb=get_resource("signac", "mem_mb"),
            walltime=get_resource("signac", "walltime")
        log:
            err=expand("{LOGDIR}/signac/{{sample}}_preprocess.err", LOGDIR = LOGDIR),
            out=expand("{LOGDIR}/signac/{{sample}}_preprocess.out", LOGDIR = LOGDIR)
        # Add here something 
        script:
            "../scripts/01_preprocess_render.R"
