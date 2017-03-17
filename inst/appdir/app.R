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
                tabPanel(style = 'margin: 20px;', id = 'home', 'Home', homeUI('home')),
                tabPanel(style = 'margin: 20px;', id = 'saved', 'Saved EODs', savedUI('saved')),
                tabPanel(style = 'margin: 20px;', id = 'help', 'Help', helpUI('help'))
            )
        )
    )
}
mserver = function(input, output, session) {
    source('page/home.R', local = T)
    source('page/saved.R', local = T)
    source('page/help.R', local = T)
    callModule(homeServer, 'home')
    callModule(savedServer, 'saved')
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
            'saved-table_rows_selected'
        )
    )
}

shinyApp(ui = ui, server = mserver, enableBookmarking = 'url')
