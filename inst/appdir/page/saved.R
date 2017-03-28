
savedUI = function(id) {
    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved EODs'),
            p('Select one or multiple EOD selections to plot them on the same axis'),
            sliderInput(ns('windowSize'), label = 'Window size', value = 0.001, min = 0.000001, max = 0.1, step = 0.000001, width='200px'),
            actionButton(ns('deleteButton'), 'Delete selected EOD(s)'),
            actionButton(ns('deleteAll'), 'Delete all EODs'),
            checkboxInput(ns('normalize'), 'Normalize selected EOD(s)'),
            checkboxInput(ns('baselineSubtract'), 'Baseline subtract selected EOD(s)'),
            checkboxInput(ns('average'), 'Average selected EOD(s)'),
            checkboxInput(ns('selectAll'), 'Select all')
        ),
        mainPanel(
            p('Saved EODs'),
            DT::dataTableOutput(ns('table')),
            plotOutput(ns('plot'),
                brush = brushOpts(
                    id = ns('plot_brush'),
                    resetOnNew = T,
                    direction = 'x'
                )
            )
        )
    )
}
savedServer = function(input, output, session, extrainput) {
    output$table = DT::renderDataTable({
        input$deleteButton
        input$deleteAll
        extrainput$saveAll
        loadData()
    })

    output$plot = renderPlot({
        if(!input$selectAll && is.null(input$table_rows_selected)) {
            return()
        }
        input$deleteButton
        input$deleteAll
        extrainput$saveView
        
        ret = loadData()
        if(input$selectAll) {
            ret = ret[input$table_rows_all, ]
        } else {
            ret = ret[input$table_rows_selected, ]
        }

        vec = NULL
#(e-s)/r$properties[['wf_increment']])
        t = numeric(0)

 
        for(i in 1:nrow(ret)) {

            s = ret[i, ]$start - input$windowSize / 2
            e = ret[i, ]$start + input$windowSize / 2

            myFilePath = ret[i, ]$file
            myFile = file(myFilePath, 'rb')
            if (!file.exists(myFilePath)) {
                return()
            }
            main = tdmsreader::TdmsFile$new(myFile)
            main$read_data(myFile, s, e)

            r = main$objects[[ret[i, ]$object]]
            t = r$time_track(start = s, end = e)
            t = t - t[1]
            dat = r$data
            close(myFile)

            if(ret[i, ]$inverted) {
                dat = -dat
            }
            
            if(input$normalize) {
                dat = (dat - min(dat)) / (max(dat) - min(dat))
            }
            if(input$baselineSubtract) {
                dat = dat - mean(dat[1:100])
            }
            if(input$average) {
                if(is.null(vec)) {
                    vec = dat
                } else {
                    vec = vec + dat[1:length(vec)]
                }
            } else {
                if(i == 1) {
                    plot(t, dat, type = 'l', xlab = 'time', ylab = 'volts')
                } else {
                    lines(t, dat, col = i)
                }
            }
        }

        if(input$average) {
            plot(t, vec[1:length(t)] / nrow(ret), type = 'l', xlab = 'time', ylab = 'volts')
        }
    })

    observeEvent(input$deleteButton, {
        ret = loadData()
        ret = ret[input$table_rows_selected, ]
        for(i in 1:nrow(ret)) {
            deleteData(ret[i, ]$start, ret[i, ]$file, ret[i, ]$object)
        }
    }, priority = 1)

    observeEvent(input$deleteAll, {
        ret = loadData()
        ret = ret[input$table_rows_all, ]
        for(i in 1:nrow(ret)) {
            r = ret[i, ]
            deleteData(r$start, r$file, r$object)
        }
    }, priority = 1)

    observe({
        reactiveValuesToList(input)
        session$doBookmark()
    })
}

