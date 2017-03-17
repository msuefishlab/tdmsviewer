
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
            plotOutput(ns('plot')),
            actionButton(ns('deleteButton'), 'Delete selected EOD')
        )
    )
}
savedServer = function(input, output, session, extrainput) {
    data = reactive({
        input$deleteButton
        extrainput$saveView
        loadData()
    })
    output$table = DT::renderDataTable({
        data()
    })

    output$plot = renderPlot({
        if(is.null(input$table_rows_selected)) {
            return()
        }
        input$deleteButton
        ret = data()
        ret = ret[input$table_rows_selected, ]
 
        s = ret[1,]$start
        e = ret[1,]$end
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

                s = ret[i,]$start
                e = ret[i,]$end
                print(ret[i,])

                myFilePath = ret[i,]$file
                myFile = file(myFilePath, 'rb')
                if (!file.exists(myFilePath)) {
                    return()
                }
                main = tdmsreader::TdmsFile$new(myFile)
                main$read_data(myFile, s, e)

                r = main$objects[[ret[i,]$object]]
                t = r$time_track(start = s, end = e)
                print(t)
                t = t-t[1]
                s = r$data
                close(myFile)

                lines(t, s, col=i)
            }
        }
    })

    observeEvent(input$deleteButton, {
        ret = data()
        ret = ret[1,]
        deleteData(ret$start, ret$end, ret$file, ret$object)
    })
}

