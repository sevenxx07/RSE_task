#!/usr/bin/env python

import argparse
import numpy as np
import pandas as pd
import umap
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
from FlowCal.io import FCSData
from fcswrite import write_fcs

def main():
    parser = argparse.ArgumentParser(description="Process FCS file")
    parser.add_argument("-i", "--input", required=True, help="Input FCS file")
    parser.add_argument("-o", "--output", required=True, help="Output FCS file")
    parser.add_argument("-p", "--plot", required=True, help="Output plot file")
    parser.add_argument("-c", "--channels", default=None, help="Optional channels.txt")
    args = parser.parse_args()

    ff = FCSData(args.input)
    expr = np.array(ff, dtype=float)

    if args.channels:
        channels_df = pd.read_csv(args.channels, sep="\t")
        selected = channels_df.loc[channels_df["use"] == 1, "desc"].tolist()
        available_channels = ff.channel_labels()
        present = [ch for ch in selected if ch in available_channels]
        indices = [available_channels.index(ch) for ch in selected]
    else:
        available_channels = ff.channel_labels()
        indices = [i for i, desc in enumerate(available_channels) if
                   desc and not any(s in desc.upper() for s in ["FSC", "SSC"])]

    X = expr[:, indices]
    X_asinh = np.arcsinh(X / 5)

    umap_res = umap.UMAP(n_components=2).fit_transform(X_asinh)

    km = KMeans(n_clusters=5, random_state=42).fit(umap_res)

    new_data = np.hstack([expr, umap_res, km.labels_[:, None]])

    new_channels = ff.channel_labels() + ["UMAP1", "UMAP2", "Cluster"]
    write_fcs(
        filename=args.output,
        chn_names=new_channels,
        data=new_data
    )

    plt.figure(figsize=(6,6))
    plt.scatter(umap_res[:,0], umap_res[:,1], c=km.labels_, cmap='tab10', s=1)
    plt.xlabel("UMAP1")
    plt.ylabel("UMAP2")
    plt.title("UMAP colored by cluster")
    plt.tight_layout()
    plt.savefig(args.plot, dpi=150)

if __name__ == "__main__":
    main()