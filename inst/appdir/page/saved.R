
savedUI = function(id) {
    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved EODs'),
            p('Select one or multiple EOD selections to plot them on the same axis'),
            sliderInput(ns('windowSize'), label = 'Window size', value = 0.001, min = 0.000001, max = 0.1, step = 0.000001, width='200px'),
            actionButton(ns('deleteButton'), 'Delete selected EOD(s)')
        ),
        mainPanel(
            p('Saved EODs'),
            DT::dataTableOutput(ns('table')),
            plotOutput(ns('plot'))
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
 
        for(i in 1:nrow(ret)) {

            s = ret[i, ]$start - input$windowSize / 2
            e = ret[i, ]$start + input$windowSize / 2

            myFilePath = ret[i,]$file
            myFile = file(myFilePath, 'rb')
            if (!file.exists(myFilePath)) {
                return()
            }
            main = tdmsreader::TdmsFile$new(myFile)
            main$read_data(myFile, s, e)

            r = main$objects[[ret[i,]$object]]
            t = r$time_track(start = s, end = e)
            t = t - t[1]
            dat = r$data
            if(ret[i, ]$inverted) {
                dat = -dat
            }
            close(myFile)
            if(i == 1) {
                plot(t, dat, type = 'l', xlab = 'time', ylab = 'volts')       
            } else {
                lines(t, dat, col = i)
            }
        }
    })

    observeEvent(input$deleteButton, {
        ret = loadData()
        ret = ret[input$table_rows_selected, ]
        for(i in 1:nrow(ret)) {
            deleteData(ret[i, ]$start, ret[i, ]$file, ret[i, ]$object)
        }
    }, priority = 1)
}

