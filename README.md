# tdmsviewer

[![Build Status](https://travis-ci.org/msuefishlab/tdmsviewer.svg?branch=master)](https://travis-ci.org/msuefishlab/tdmsviewer)

Programs for seeking and analyzing LabVIEW tdms files

## Install


    install.packages('devtools')
    devtools::install_github('msuefishlab/tdmsviewer')

## Usage

A Rmd vignette which includes installation instructions and user manual is available, see <https://msuefishlab.github.io/tdmsviewer/>

Basic usage

    library(tdmsviewer)
    tdmsviewer(basedir='~/tdms_files')

## Screenshot

![](img/1.png)


## Notes

Based on the [tdmsreader](https://github.com/msuefishlab/tdmsreader) package
