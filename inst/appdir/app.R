source('global.R')

ui = function() {
    source('page/home.R', local = T)
    source('page/saved.R', local = T)
    source('page/help.R', local = T)
    source('page/landmark_page.R', local = T)
    fluidPage(
        includeCSS('styles.css'),
        headerPanel('tdmsviewer'),
        wellPanel(style = 'background-color: #ffffff;', 
            tabsetPanel(id = 'inTabset',
                tabPanel(style = 'margin: 20px;', id = 'home', 'Home', homeUI('home')),
                tabPanel(style = 'margin: 20px;', id = 'saved', 'Saved EODs', savedUI('saved')),
                tabPanel(style = 'margin: 20px;', id = 'landmarkpage', 'Landmarks', landmarkpageUI('landmarkpage')),
                tabPanel(style = 'margin: 20px;', id = 'help', 'Help', helpUI('help'))
            )
        )
    )
}
server = function(input, output, session) {
    source('page/home.R', local = T)
    source('page/saved.R', local = T)
    source('page/help.R', local = T)
    source('page/landmark_page.R', local = T)
    extrainput = callModule(homeServer, 'home')
    moreinput = callModule(savedServer, 'saved', extrainput)
    callModule(landmarkpageServer, 'landmarkpage', moreinput)
    callModule(helpServer, 'help')

    observe({
        reactiveValuesToList(input)
        session$doBookmark()
    })
    onBookmarked(function(url) {
        updateQueryString(url)
    })
    setBookmarkExclude(
        c(
            'saved-table_rows_current',
            'saved-table_cell_clicked',
            'saved-table_rows_all',
            'saved-table_state',
            'saved-table_rows_selected',
            'saved-deleteButton',
            'saved-analyzeWaveform',
            'saved-saveLandmarksButton',
            'saved-landmark-save_landmark',
            'saved-landmark-time_value',
            'saved-landmark-landmark',
            'home-moveRight',
            'home-moveLeft',
            'home-zoomOut',
            'home-zoomIn',
            'home-saveAll',
            'home-plot_brush'
        )
    )
}

shinyApp(ui = ui, server = server, enableBookmarking = 'url')
