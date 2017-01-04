# tdmsviewer

Programs for seeking and analyzing LabVIEW tdms files

# Prerequisites

R packages:

- shiny
- tdmsreader

Note: tdmsreader is not currently an official R package so it is recommended to first install the package `devtools` and then run `devtools::install_github('msuefishlab/tdmsreader')`

## Setup

The TDMS files can be put within a folder structure like this:

```
└── data
    ├── day1
    │   ├── exp1.tdms
    │   └── exp2.tdms
    └── day2
        ├── exp1.tdms
        ├── exp2.tdms
        └── exp3.tdms

```

## Start server

Execute the command

- Rscript -e 'shiny::runApp()'

Alternatively open the ui.R and server.R files in RStudio and click 'Run app'
