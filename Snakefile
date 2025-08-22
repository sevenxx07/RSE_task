config = {
    "script_type": "python",  # "python" or "R"
    "use_channels": True      # True or False
}

import os, glob

RAW_DIR = config.get('raw_dir', 'data/raw')
PROCESSED_DIR = config.get('processed_dir', 'data/processed_channels_py')
PLOT_DIR = config.get('plot_dir', 'plots_channels_py')
CHANNELS_FILE = config.get('channels_file', 'channels.txt')
SCRIPT_TYPE = config["script_type"]
USE_CHANNELS = config["use_channels"]

samples = [os.path.splitext(os.path.basename(f))[0] for f in glob.glob(os.path.join(RAW_DIR, '*.fcs'))]

rule all:
    input:
        expand(os.path.join(PROCESSED_DIR, '{sample}_umap_clust.fcs'), sample=samples),
        expand(os.path.join(PLOT_DIR, '{sample}.png'), sample=samples)

rule process_fcs:
    input:
        os.path.join(RAW_DIR, '{sample}.fcs')
    output:
        fcs=os.path.join(PROCESSED_DIR, '{sample}_umap_clust.fcs'),
        plot=os.path.join(PLOT_DIR, '{sample}.png')
    params:
        channels_flag=lambda wildcards: f"-c {CHANNELS_FILE}" if USE_CHANNELS else "",
        script_type=SCRIPT_TYPE
    shell:
        """
        if [ "{params.script_type}" = "python" ]; then
            python {workflow.basedir}/scripts/process_fcs.py \
                -i "{input}" -o "{output.fcs}" -p "{output.plot}" {params.channels_flag}
        else
            Rscript {workflow.basedir}/scripts/process_fcs.R \
                -i "{input}" -o "{output.fcs}" -p "{output.plot}" {params.channels_flag}
        fi
        
        """
        
        #'Rscript {workflow.basedir}/scripts/process_fcs.R -i "{input}" -o "{output.fcs}" -p "{output.plot}" -c "{params.channels_file}"'
