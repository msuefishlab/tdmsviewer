library(shiny)
library(tdmsreader)
library(futile.logger)

flog.threshold(DEBUG)

# open file
shinyServer(function(input, output) {


    dataInput <- reactive({
        withProgress(message = 'Loading...', value = 0, {
            my_file = file(paste0(input$dir, '/', input$dataset), "rb")
            x = TdmsFile$new(my_file)
            close(my_file)
            return (x)
        })
    })


    output$dirs <- renderUI({
        dirs = list.files('data', full.names = T)
        selectInput("dir", "Data group", dirs)
    })


    output$datasets <- renderUI({
        if (is.null(input$dir)) {
            return()
        }
        tdmss = list.files(input$dir, pattern = ".tdms$")
        selectInput("dataset", "TDMS File", tdmss)
    })

    output$objects <- renderUI({
        if (is.null(input$dataset)) {
            return()
        }
        datatable <- dataInput()
        l = list()
        for(elt in ls(datatable$objects)) {
            if(datatable$objects[[elt]]$has_data) {
                l[[elt]] = elt
            }
        }
        selectInput("object", "TDMS Object", l)
    })

    output$distPlot <- renderPlot({
        if (is.null(input$object)) {
            return()
        }

        s = ifelse(!is.null(ranges2$xmin), ranges2$xmin, 0)
        e = ifelse(!is.null(ranges2$xmax), ranges2$xmax, 1)
        my_file = file(paste0(input$dir, '/', input$dataset), "rb")
        main = TdmsFile$new(my_file)
        main$read_data(my_file, s, e)

        r = main$objects[[input$object]]
        t = r$time_track(start = s, end = e)
        s = r$data
        close(my_file)

        plot(t, s, type = 'l', xlab = 'time', ylab = 'volts')
    })


    ranges2 <- reactiveValues(xmin = NULL, xmax = NULL)


    observe({
        brush <- input$plot_brush
        ranges2$xmin <- brush$xmin
        ranges2$xmax <- brush$xmax
    })
})
