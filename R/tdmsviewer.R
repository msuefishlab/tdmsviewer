#' Launch the tdmsviewer app
#'
#' Executing this function will launch the tdmsviewer application in
#' the user's default web browser.
#' @author Colin Diesh \email{dieshcol@msu.edu}
#' @examples
#' \dontrun{
#' tdmsviewer()
#' }

#' @export
tdmsviewer <- function() {
    runTdmsViewer()
    return(invisible())
}


runTdmsViewer <- function(args, baseDir){
    filename <-  base::system.file("appdir", package = "tdmsviewer")
    shiny::runApp(filename, launch.browser = TRUE)
}
