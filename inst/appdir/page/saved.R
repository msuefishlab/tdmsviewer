
savedUI = function(id) {
    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved EODs'),
            p('Select one or multiple EOD selections to plot them on the same axis')
        ),
        mainPanel(
            p('Saved EODs'),
            DT::dataTableOutput(ns('table')),
            sliderInput(ns('windowSize'), label = "Window size", value = 0.001, min = 0.000001, max = 0.1, step = 0.000001),
            plotOutput(ns('plot')),
            actionButton(ns('deleteButton'), 'Delete selected EOD')
        )
    )
}
savedServer = function(input, output, session, extrainput) {
    output$table = DT::renderDataTable({
        input$deleteButton
        extrainput$saveView
        loadData()
    })

    output$plot = renderPlot({
        if(is.null(input$table_rows_selected)) {
            return()
        }
        input$deleteButton
        extrainput$saveView
        
        ret = loadData()
        ret = ret[input$table_rows_selected, ]
 
        s = ret[1,]$start - input$windowSize/2
        e = ret[1,]$start + input$windowSize/2
        myFilePath = ret[1,]$file
        myFile = file(myFilePath, 'rb')
        if (!file.exists(myFilePath)) {
            return()
        }
        main = tdmsreader::TdmsFile$new(myFile)
        main$read_data(myFile, s, e)

        r = main$objects[[ret[1,]$object]]
        t = r$time_track(start = s, end = e)
        t = t-t[1]
        s = r$data
        close(myFile)

        plot(t, s, type = 'l', xlab = 'time', ylab = 'volts')       
        if(nrow(ret)>1) {
            for(i in 2:nrow(ret)) {

                s = ret[i,]$start - input$windowSize/2
                e = ret[i,]$start + input$windowSize/2

                myFilePath = ret[i,]$file
                myFile = file(myFilePath, 'rb')
                if (!file.exists(myFilePath)) {
                    return()
                }
                main = tdmsreader::TdmsFile$new(myFile)
                main$read_data(myFile, s, e)

                r = main$objects[[ret[i,]$object]]
                t = r$time_track(start = s, end = e)
                t = t-t[1]
                s = r$data
                close(myFile)

                lines(t, s, col=i)
            }
        }
    })

    observeEvent(input$deleteButton, {
        ret = loadData()
        ret = ret[1,]
        deleteData(ret$start, ret$file, ret$object)
    }, priority = 1)
}

