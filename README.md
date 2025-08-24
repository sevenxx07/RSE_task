# FCS Analysis Pipeline

This repository contains a Snakemake workflow for analyzing FCS files. For each
input file the pipeline performs the following steps:

1. Selects channels with a non-empty description excluding scatter channels.
2. Applies an `asinh` transformation with cofactor 5.
3. Computes a 2D UMAP embedding.
4. Performs k-means clustering (5 clusters) in the original space (over the transformed channels).
5. Writes a new FCS file containing UMAP coordinates and cluster labels.
6. Generates a UMAP plot coloured by cluster.


## Installation

Create a conda environment and install the dependencies:

```bash
conda env create -f environment.yml
conda activate fcs_pipeline
```

## Running the pipeline

Place your FCS files into `data/raw` and run:

```bash
snakemake --cores 4
```
## Configuring pipeline

You can configure the pipeline from Snakefile script.

At the beginning of the script there is config:

```bash
config = {
    "script_type": "python",  # "python" or "R"
    "use_channels": False      # True or False
}
```
Set script_type to python or R. Both scripts are doing exactly same thing, they are just written in different programming language.

Set use_channels on True, if you want to use .txt file with defined channels that should work like a filter for channels in FCS file/s.

To set name of channel .txt look for this line in Snakefile:

```bash
CHANNELS_FILE = config.get('channels_file', 'channels.txt')
```

Outputs will be written to `data/processed` and `plots`. However if you want to use some other directory, set it also in Snakefile on these lines:

```bash
PROCESSED_DIR = config.get('processed_dir', 'data/processed')
PLOT_DIR = config.get('plot_dir', 'plots')
```

## Docker

Build a Docker image containing all dependencies:

```bash
docker build -t fcs_pipeline .
```

Run the pipeline using the image:

```bash
docker run --rm -v $(pwd):/data -w /pipeline fcs_pipeline --cores 4
```
