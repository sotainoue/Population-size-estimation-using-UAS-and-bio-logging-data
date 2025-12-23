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
│       ├── logging_data.csv　# individual tracking data
│       ├── n_image.csv # number of images to create each orthomosaic
│       ├── test_data.csv # result of validation in object detection
│       └── uas_counts.csv # prediction for orthomosaic
│
├── code/
│   ├── clean_logging_data.R   # Cleaning raw bio-logging data
│   ├── clean_uas_detection.R  # Cleaning raw UAS detection data
│   ├── main.R                 # Main analysis
│   └── figure.R               # Figure generation
│
├── output/               # Generated results and figures
│   ├── ssmn_fit.rds # fitted result for ssmn
│   ├── ssmp_fit.rds # fitted result for ssmp
│   ├── sub_sample.rds # sub-sampled result for creating figures 
│   ├── full_dens_df.rds # density of sub-sampled result
│   ├── full_ci_df.rds # ci of sub-sampled result
│   ├── dist_data.rds # result of Wassestein distance
│   ├── b_data.csv # temporal .csv for model fitting (presense result in the colony)
│   ├── uas_data2.csv # temporal .csv for model fitting (count result)
│   ├── cb_data.csv # temporal .csv for model fitting (combined .csv of bio-logging and uas)
│   ├── df_posterior_summary.csv # fitted result for ssmn
│   └── table_s3.csv # estimated values of each parameter
│
├── ssm_model/
│   ├── ssmn.stan
│   └── ssmp.stan
│
├── object_detection/
│   ├── best.pt
│   ├── environment.yml
│   ├── example.png
│   ├── training_data/
│   └── training.ipynb
│
├── counting_gulls-5FBE.Rproj
└── README.md
```

## Data availability

The processed datasets required to reproduce all analyses and figures are provided in data/derived/.
These datasets were generated from raw data using the scripts in R/clean_logging_data.R and
R/clean_uas_detection.R.

Raw data are not publicly available due to ethical considerations, data sensitivity, 
and file size limitations (e.g., individual-level tracking data and high-resolution UAS imagery).
However, all preprocessing steps required to generate the shared datasets are fully documented 
and reproducible using the provided scripts.

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
source('clean_logging_data.R')
source('clean_uas_detection.R')
source('main.R')
source('figure.R')
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

### GPU and CUDA notes

Object detection was performed using PyTorch and YOLOv8.
The original analyses were run with PyTorch built against CUDA 11.8
on NVIDIA GPUs.

GPU acceleration is optional. If CUDA is not available, the code
automatically falls back to CPU execution, although inference will be slower.

We recommend using:
- Python 3.10
- PyTorch (CUDA 11.8 build)
- NVIDIA driver ≥ 520

