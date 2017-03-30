#' Launch the tdmsviewer app
#'
#' Executing this function will launch the tdmsviewer application in
#' with a given folder of TDMS files
#' @examples
#' \dontrun{
#' tdmsviewer(basedir='/data/dir')
#' }
#' @export
#' @param basedir Root directory for TDMS files. Default '~'
#' @param dev Boolean if using dev environment, loads from local directories
tdmsviewer = function(basedir = '~', dev = F) {
    .GlobalEnv$basedir <- basedir
    on.exit(rm(basedir, envir = .GlobalEnv))
    if (!dev) {
        shiny::runApp(base::system.file("appdir", package = "tdmsviewer"), launch.browser = T)
    } else {
        shiny::runApp('inst/appdir', launch.browser = T)
    }
}
