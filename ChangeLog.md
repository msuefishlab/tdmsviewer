## Version 0.7.0 = August 14th, 2017

- Add ability to save sessions
- Clean up SQLite database code that was spawning too many open files errors

## Version 0.6.0 - August 9th, 2017

- Add ability to view the saved EODs as little red dots on the results screen
- Update peak finding algorithm to use newer eodplotter version with adaptive variation

## Version 0.5.3 - July 7th, 2017

- Fix issues with shinyFiles
- Integrate with eodplotter library (https://github.com/msuefishlab/eodplotter)

## Version 0.5.2 - April 7th, 2017

- Identify zc1 and zc2 baseline crossing timepoints
- Only identify p0 within 0.5ms of the zc1 timepoint

## Version 0.5.1 - April 7th, 2017

- Improve performance on the "Saved EODs" by applying normalization/transformations on already-loaded data instead of reloading every time
- Fix issue with the TDMS file view jumping around

## Version 0.5.0 - April 4th, 2017

- Add automatic landmark identification and labeling
- Add download of mean and stddev landmark values
- Add basic in-app help guide

## Version 0.4.1 - March 30th, 2017

- Updated DESCRIPTION
- Added user guide vignette
- Added downsampling when large TDMS area viewed
- Added option for configuring sqlite DB path
- Added workaround to launch internet browser instead of RStudio built-in browser

## Version 0.4.0 - March 29th, 2017

- Added interactive landmark editing functions for EOD

## Version 0.3.0 - March 28th, 2017

- Changed directory selector to file selector
- Enhanced bookmarking ability so page refreshes loads same file
- Added peak finder and user definable cutoff thresholds for sigma or voltage
- Added ggplot2 for average EOD values
- Added download buttons for EOD waveforms as CSV

## Version 0.2.0 - March 24th, 2017

- Added file selector
- Added ability to plot saved EODs
- Added ability to save EOD to SQLite database
- Added peak finder based on sigma cutoff

## Version 0.1.0 - Feburuary 23rd, 2017

- Organized `tdmsviewer` as a package that can be installed with `devtools`
- Basic ability to select a directory on both Windows and Linux
- Zoom in/Zoom out/Slide left/Slide right buttons
