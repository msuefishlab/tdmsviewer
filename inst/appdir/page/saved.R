
savedUI = function(id) {
    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved EODs')
        ),
        mainPanel(
            p('Saved EODs'),
            DT::dataTableOutput(ns('table'))
        )
    )
}
savedServer = function(input, output, session) {
    
    output$table <- DT::renderDataTable({
        input$saveView
        loadData()
    })
}

