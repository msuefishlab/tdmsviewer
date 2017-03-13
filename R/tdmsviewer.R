
#' Launch the tdmsviewer app
#'
#' Executing this function will launch the tdmsviewer application in
#' the user's default web browser.
#' @author Colin Diesh \email{dieshcol@msu.edu}
#' @examples
#' \dontrun{
#' tdmsviewer()
#' }
#' @import shiny shinyFiles


#' @export
tdmsviewer <- function(baseDir = '~') {
    runTdmsViewer(baseDir)
    return(invisible())
}


runTdmsViewer <- function(baseDir){
    .GlobalEnv$.baseDir <- baseDir
    on.exit(rm(.baseDir, envir = .GlobalEnv))
    filename <-  base::system.file("appdir", package = "tdmsviewer")
    runApp(filename, launch.browser = TRUE)
}
