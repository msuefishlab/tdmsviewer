
#' Launch the tdmsviewer app
#'
#' Executing this function will launch the tdmsviewer application in
#' the user's default web browser.
#' @examples
#' \dontrun{
#' tdmsviewer(basedir='~')
#' }
#' @export
#' @param basedir Base directory for the file chooser


#' @export
tdmsviewer <- function(basedir = '~') {
    runTdmsViewer(basedir)
    return(invisible())
}


runTdmsViewer <- function(basedir){
    .GlobalEnv$basedir <- basedir
    on.exit(rm(basedir, envir = .GlobalEnv))
    filename <-  base::system.file("appdir", package = "tdmsviewer")
    runApp(filename, launch.browser = TRUE)
}
