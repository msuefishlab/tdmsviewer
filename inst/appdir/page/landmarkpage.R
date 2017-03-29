landmarkpageUI = function(id) {

    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved landmarks'),
            p('View landmark data'),
            actionButton(ns('refresh'), 'Refresh'),
            actionButton(ns('deleteAll'), 'Delete landmark(s)')
        ),
        mainPanel(
            DT::dataTableOutput(ns('table'))
        )
    )
}
landmarkpageServer = function(input, output, session, extrainput) {
    getData = reactive({
        input$deleteAll
        input$refresh
        loadLandmarks()
    })

    observeEvent(input$deleteAll, {
        ret = getData()
        ret = ret[input$table_rows_all, ]
        for(i in 1:nrow(ret)) {
            r = ret[i, ]
            deleteLandmark(r$landmark, r$description)
        }
    }, priority = 1)

    output$table = DT::renderDataTable({
        getData()
    })
}

