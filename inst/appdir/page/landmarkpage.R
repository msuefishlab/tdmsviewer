landmarkpageUI = function(id) {

    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved landmarks'),
            p('View landmark data')
        ),
        mainPanel(
            DT::dataTableOutput(ns('table'))
        )
    )
}
landmarkpageServer = function(input, output, session, extrainput) {
    output$table = DT::renderDataTable({
        loadLandmarks()
    })

}

