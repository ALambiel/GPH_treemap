# GPH_treemap
This repository contains R scripts used for high resolution tree species classification, performed for the Gruyère Pays d'Enhaut Regional Nature park, located in the Swiss Pre Alps. These maps are outcomes from the ValPar.CH project.

![Graphical abstract](https://github.com/ALambiel/GPH_treemap/blob/main/images/graphical_abstract.jpg)

## 📖 Methodology and references 

The general workflow is presented here after. 

![General workflow](https://github.com/ALambiel/GPH_treemap/blob/main/images/workflow.png)
 
Output maps are available in the [Zenodo repository ](https://zenodo.org/xxx)

## 📂 Folder structure

This repository follows the above structure:
```
GPH_treemap/
│── run/
│   ├── 01_get_lidar_data/          # download LiDAR data based on urls and normalized data
|   ├── 02_itc_delineating/         # compute Canopy Height Model and proceed to Individual Tree Crown delineation
│   ├── 03_hsi_extraction/          # get spectral information for model input
│   ├── 04_lidar_derived_metrics/   # compute LiDAR derived metrics as potential covariates
│   ├── 05_treemap_classification/  # fit, predict and eval 
│   └── 06_postprocess/             # clean final map
└── README.md                       # this documentation
```

## Map Display

You can view the generated maps showcasing the tree species classification:

![Tree species map](https://github.com/ALambiel/GPH_treemap/blob/main/images/gph_treemap.jpg)


## Related publication

Lambiel, A., Gerber, L., Schweiger, A.K., Kneubühler, M., Mariéthoz, G., Lehmann, A., & Külling, N. (in prep). Large-scale individual tree species mapping using AVIRIS-NG and LiDAR data fusion.
