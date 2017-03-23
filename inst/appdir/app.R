source('global.R')

ui = function() {
    source('page/home.R', local = T)
    source('page/saved.R', local = T)
    source('page/help.R', local = T)
    fluidPage(
        includeCSS('styles.css'),
        headerPanel('tdmsviewer'),
        wellPanel(style = 'background-color: #ffffff;', 
            tabsetPanel(id = 'inTabset',
                tabPanel(style = 'margin: 20px;', id = 'home', 'Home',
                    sidebarLayout(
                        sidebarPanel(
                            shinyFiles::shinyDirButton('dir', label = 'Directory select', title = 'Please select a directory'),
                            homeSidebarUI('home')
                        ),
                        mainPanel(
                            homeMainUI('home')
                        )
                    )
                ),
                tabPanel(style = 'margin: 20px;', id = 'saved', 'Saved EODs', savedUI('saved')),
                tabPanel(style = 'margin: 20px;', id = 'help', 'Help', helpUI('help'))
            )
        )
    )
}
server = function(input, output, session) {
    shinyFiles::shinyDirChoose(input, 'dir', session = session, roots = c(home = basedir))
    source('page/home.R', local = T)
    source('page/saved.R', local = T)
    source('page/help.R', local = T)
    extrainput = callModule(homeServer, 'home', input)
    callModule(savedServer, 'saved', extrainput)
    callModule(helpServer, 'help')
    observeEvent(input$inTabset, {
        session$doBookmark()
    })
    onBookmarked(function(url) {
        updateQueryString(url)
    })
    setBookmarkExclude(
        c(
            'saved-table_rows_current',
            'saved-table_cell_clicked',
            'saved-table_search',
            'saved-table_rows_all',
            'saved-table_state',
            'saved-table_rows_selected',
            'home-saveView',
            'dir-modal',
            'dir',
            'home-saveInvertedView',
            'home-saveView',
            'home-moveRight',
            'home-moveLeft',
            'home-zoomOut',
            'home-zoomIn',
            'home-dataset',
            'home-object',
            'saved-deleteButton',
            'home-plot_brush'
        )
    )
}

shinyApp(ui = ui, server = server, enableBookmarking = 'url')
