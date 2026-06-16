# Population size estimation using UAS and bio-logging data

This repository contains the data and code used to reproduce the analyses and figures in the manuscript:

> **Integration of UAS-based spatial surveys and bio-logging tracking enhances precision in population size estimation**

---

## Repository structure

```text
.
├── data/
│   ├── raw/              # Raw data (not publicly available)
│   └── derived/          # Processed data used for analyses (shared)
│       ├── logging_data.csv # individual tracking data
│       ├── n_image.csv # number of images to create each orthomosaic
│       ├── test_data.csv # result of validation in object detection
│       └── uas_data.csv # prediction for orthomosaic
│
├── code/
│   ├── clean_logging_data.R   # Cleaning raw bio-logging data
│   ├── clean_uas_detection.R  # Cleaning raw UAS detection data
│   ├── main.R                 # Main analysis
│   └── figure.R               # Figure generation
│
├── output/               # Generated results and figures
│   ├── ssmp_fit.rds # fitted result for ssmp; available on Dryad
│   ├── sens_fit_1.rds # fitted result for ssmn with delta theta=-0.8; available on Dryad
│   ├── sens_fit_2.rds # fitted result for ssmn with delta theta=-0.4; available on Dryad
│   ├── sens_fit_3.rds # fitted result for ssmn with delta theta=0 ; available on Dryad
│   ├── sens_fit_4.rds # fitted result for ssmn with delta theta=0.4; available on Dryad
│   ├── sens_fit_5.rds # fitted result for ssmn with delta theta=0.8; available on Dryad
│   ├── sub_sample.rds # sub-sampled result for creating figures ; available on Dryad
│   ├── full_dens_df.rds # density of sub-sampled result; available on Dryad
│   ├── full_ci_df.rds # ci of sub-sampled result; available on Dryad
│   ├── dist_data.rds # result of Wassestein distance
│   ├── b_data.csv # temporal .csv for model fitting (presense result in the colony)
│   ├── uas_data2.csv # temporal .csv for model fitting (count result)
│   ├── cb_data.csv # temporal .csv for model fitting (combined .csv of bio-logging and uas)
│   ├── df_posterior_summary.csv # fitted result for ssmn; available on Dryad
│   └── table_s3.csv # estimated values of each parameter
│
├── ssm_model/
│   ├── ssmn.stan
│   └── ssmp.stan
│
├── object_detection/
│   ├── best.pt # trained weight 
│   ├── environment.yml # environment config
│   ├── example.png # example of orthomosaic
│   ├── training_data/ # training data
│   └── training.ipynb # jupyter notebook for training, prediction, and batch prediction
│
├── counting_gulls-5FBE.Rproj
└── README.md
```

## Data availability

The processed datasets required to reproduce all analyses and figures are provided in data/derived/.
These datasets were generated from raw data using the scripts in code/clean_logging_data.R and
code/clean_uas_detection.R.

Raw data are not publicly available due to file size limitations (e.g., individual-level tracking data and high-resolution UAS imagery).
However, all preprocessing steps required to generate the shared datasets are fully documented 
and reproducible using the provided scripts.

Large generated output files are not included in this GitHub repository due to file size limitations. 
The fitted model objects and simulation outputs required for reproducing the figures are available separately on Dryad.
These data will be available from Dryad upon publication.

## Requirements

All analyses were conducted in R (version 4.5.1).

The following R packages are required:
- tidyverse
- geosphere
- stringr
- ggmap
- ggsci
- jsonlite
- base64enc
- janitor
- lubridate
- fs
- sp
- rstan
- bayesplot
- lme4
- cowplot
- ggimage
- sf
- ggpubr
- zoo
- viridis
- FNN
- rnaturalearth
- rnaturalearthdata

To install required packages:
```r
install.packages(c("tidyverse", "geosphere", "stringr", "ggmap",
                   "ggsci","jsonlite","base64enc","janitor","lubridate",
                   "fs","sp","rstan","bayesplot","lme4","cowplot","ggimage",
                   "sf","ggpubr","zoo","viridis","FNN"))
```

# How to reproduce the analysis
1.	Clone or download this repository.
2.	Open R and set the working directory to the root of the repository.
3.	Run the main script:


```r
install.packages("renv")
renv::restore()
source('code/clean_logging_data.R')
source('code/clean_uas_detection.R')
source('code/main.R')
source('code/figure.R')
```


We recommend opening the RStudio project file (`counting_gulls-5FBE.Rproj`) 
before running the scripts to ensure correct path handling using the `here` package.

This script will:
	•	Load processed data from data/derived/
	•	Fit all statistical models
	•	Generate all figures used in the manuscript
	•	Save outputs to the output/ directory

## Computational notes

Bayesian models were fitted using Stan.
The full analyses used 20,000 iterations (10,000 warmup) per chain, 
which may require several hours depending on hardware.

For quick testing and code verification, reduced iterations are specified in `main.R`.


# Python environment for object detection (YOLOv8 + SAHI)

The object detection pipeline requires a dedicated Python environment
due to strong dependencies on CUDA, PyTorch, OpenCV, and NumPy.

## 1. Create the conda environment

```bash
conda env create -f object_detection/environment.yml
conda activate counting_gulls
```

## 2. Register the environment as a Jupyter kernel

```bash
pip install ipykernel
python -m ipykernel install --user \
  --name counting_gulls \
  --display-name "Python (counting_gulls)"
```
Restart Jupyter and select Python (counting_gulls) as the kernel.

## 3. Notes on reproducibility

	•	GPU acceleration is supported if a compatible CUDA driver is available.
	•	CPU-only execution is also possible but slower.
	•	All object detection results in the manuscript were generated using this environment.

## Note on orthomosaic batch prediction (not runnable in the shared repository)

The script section **"Batch prediction for orthomosaics"** requires access to the original orthomosaic GeoTIFF files.
These orthomosaics are **not included** in this repository due to data size and sensitivity constraints.

Therefore, this part is **disabled by default** (or will be skipped) in the shared/public version.

To run it locally (only for authorized users), you must:
1. Obtain the orthomosaic files separately.
2. Set `ORTHO_GLOB` to the local path(s) of the orthomosaic folders.
3. (If applicable) enable execution by setting an environment variable, e.g.:

```bash
export RUN_PRIVATE_ORTHO=1
```

## Citation

If you use this code, data, or trained model weights, please cite the associated preprint:
Inoue, ... (2026). Integration of UAS-based spatial surveys and bio-logging tracking enhances precision in population size estimation. bioRxiv. https://doi.org/10.64898/2026.01.25.701645
Citation information is also provided in `CITATION.cff`.
Please refer to the latest version of the preprint on bioRxiv.

## License

The analysis code in this repository, including the R scripts, Stan models, and Python notebooks, is released under the MIT License. See `LICENSE` for details.
The datasets included in this repository and the large supplementary files deposited on Dryad are released under the license specified in the Dryad record. If not otherwise specified, these data are provided under the Creative Commons Attribution 4.0 International License (CC BY 4.0).
The trained object detection model weights (`object_detection/best.pt`) are provided for reproducibility of the analyses in the associated manuscript. Please cite the associated paper and this repository when using the model weights, code, or data.
Large generated output files are deposited on Dryad and will be linked here upon publication.
