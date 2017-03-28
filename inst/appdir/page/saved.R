library(ggplot2)
library(reshape2)

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
            checkboxInput(ns('preBaselineSubtract'), 'Pre-baseline subtract selected EOD(s)'),
            checkboxInput(ns('postBaselineSubtract'), 'Post-baseline subtract selected EOD(s)'),
            checkboxInput(ns('average'), 'Average selected EOD(s)'),
            checkboxInput(ns('selectAll'), 'Select all')
        ),
        mainPanel(
            DT::dataTableOutput(ns('table')),
            plotOutput(ns('plot'),
                click = ns('plot_click'),
                height = '700px'
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
        extrainput$saveAll
        
        ret = loadData()
        if(input$selectAll) {
            ret = ret[input$table_rows_all, ]
        } else {
            ret = ret[input$table_rows_selected, ]
        }

        vec = NULL
        t = numeric(0)
        plotdata = data.frame(col = numeric(0), time = numeric(0), dat = numeric(0))
 
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
            t = t - ret[i, ]$start
            dat = r$data
            close(myFile)

            if(ret[i, ]$inverted) {
                dat = -dat
            }
            if(input$preBaselineSubtract) {
                dat = dat - mean(dat[1:50])
            }
            if(input$normalize) {
                dat = (dat - min(dat)) / (max(dat) - min(dat))
            }
            if(input$postBaselineSubtract) {
                dat = dat - mean(dat[1:50])
            }
            # rounding important here to avoid different values being collapsed. significant digits may change on sampling rate of tdms
            b = data.frame(col = i, time = round(t, digits=5), data = dat)
            plotdata = rbind(plotdata, b)
        }

        print(head(acast(plotdata, time~col)))

        if(input$average) {
            ggplot(data=plotdata, aes(x=time, y=data)) + stat_summary(aes(y = data), fun.y=mean, geom="line")
        } else {
            ggplot(data=plotdata, aes(x=time, y=data, group=col)) + geom_line()
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


    observeEvent(input$plot_click, {
        showModal(modalDialog(
            title = "Landmark editor",
            tagList(
                selectInput(session$ns('landmark'), 'Landmark', c('ZC1','T1','P0','S1','P1','S2','ZC2','P2','T2')),
                numericInput(session$ns('time_val'), 'Time', value = input$plot_click$x),
                numericInput(session$ns('volt_val'), 'Volts', value = input$plot_click$y),
                textInput(session$ns('peak_set'),  'EOD type', value = '<changeme>'),
                actionButton(session$ns('save_landmark'), 'Save')
            )
        ))
    })

    observeEvent(input$save_landmark, {
         print(sprintf('landmark %s val %f,%f', input$landmark, input$time_val, input$volt_val))
    })
}

