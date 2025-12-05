# Large-scale individual tree species mapping using AVIRIS-NG and LiDAR data fusion

## 📄 Description
This repository contains scripts associated with the study "Large-scale individual tree species mapping using AVIRIS-NG and LiDAR data fusion", which investigates the use of hyperspectral imaging and LiDAR data for individual tree crown level species classification in the Swiss Pre-Alps.

The main goal is to demonstrate the potential of hyperspectral (AVIRIS-NG) and LiDAR data to procude continuous, high resolution tree species maps using machine learning techniques.
Output maps are available in the [Zenodo repository ](https://doi.org/10.5281/zenodo.17805682). These maps are outcomes from the ValPar.CH project. 

![Graphical abstract](https://github.com/ALambiel/GPH_treemap/blob/main/images/graphical_abstract.png)

## 🛠️ Workflow

![Workflow](https://github.com/ALambiel/GPH_treemap/blob/main/images/workflow.png)

The scripts available in this repository allow you to prepare LiDAR data, extract spectral information and build a Random Forest model. They also enable you to make predictions and post-process the obtained maps. 

## 📈 Key results

- Overall accuracy: 74% (hyperspectral only), 76% (hyperspectral + LiDAR).
- Best performance: Fusion of hyperspectral and LiDAR data.
- Gap-filling: Produced a continuous species map preserving spatial patterns.

## 🔍 Map display

You can view the generated map showcasing the tree species classification (hyperspectral-only).

![Tree species map](https://github.com/ALambiel/GPH_treemap/blob/main/images/gph_treemap.jpg)

## 📂 Repository structure

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

## 🔗 Related publication

Lambiel, A., Gerber, L., Schweiger, A.K., Kneubühler, M., Mariéthoz, G., Lehmann, A., & Külling, N. (in prep). Large-scale individual tree species mapping using AVIRIS-NG and LiDAR data fusion.

## ✅ License
This project is licensed under Creative Commons Attribution 4.0 International.