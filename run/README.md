## 🛠️ Workflow

The general workflow is presented here after. 

![General workflow](https://github.com/ALambiel/GPH_treemap/blob/main/images/workflow.png)

The available scripts allow you to prepare LiDAR data, extract spectral information and build a Random Forest model. They also enable you to make predictions and post-process the obtained maps. 

## 📂 Folder structure

This folder follows the above structure:
```
GPH_treemap/
│── run/
    ├── 01_get_lidar_data/
    │   ├── 01_downloadingLiDAR.r
    │   └── 02_normalizeLiDAR.r
    ├── 02_itc_delineating/
    │   ├── 01_CanopyHeightModel.r
    │   ├── 02_LiDARsegmentation.r
    │   └── 03_IndividualTreeCrown.r
    ├── 03_hsi_extraction/
    │   ├── 01_extract_hyperspectral_information.r
    │   └── 02_clean_hyperspectral_information.r
    ├── 04_lidar_derived_metrics/
    │   ├── 01_elevation_metrics.r
    │   ├── 01_intensity_metrics.r
    │   ├── 01_returnnumber_metrics.r
    │   ├── 01_treeshape_metrics.r
    │   ├── 02_covar_selection.r
    │   └── optional_mosaic.r
    ├── 05_treemap_classification/
    │   ├── 01_fit_and_train_RF.r
    │   └── 02_prediction.r
    └── 06_postprocess/
        └── treemap_postprocessing.r
   
```
