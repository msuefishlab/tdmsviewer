library(shiny)
library(tdmsreader)
library(futile.logger)

# open file
shinyServer(function(input, output, session) {
    dataInput <- reactive({
        withProgress(message = 'Loading...', value = 0, {
            my_file = file(paste0(input$dir, '/', input$dataset), "rb")
            x = TdmsFile$new(my_file)
            close(my_file)
            return (x)
        })
    })

    ranges <- reactiveValues(xmin = 0, xmax = 1)

    observeEvent(input$plot_brush, {
        brush <- input$plot_brush
        if (!is.null(brush)) {
            updateSliderInput(session, "sliderRange", value = c(brush$xmin, brush$xmax))
        }
    })

    observeEvent(input$sliderRange, {
        ranges$xmin <- input$sliderRange[1]
        ranges$xmax <- input$sliderRange[2]
    })

    observeEvent(input$zoomIn, {
        t1 = ranges$xmax
        t2 = ranges$xmin
        a = t2 + (t1 - t2) / 3
        b = t1 - (t1 - t2) / 3
        updateSliderInput(session, "sliderRange", value = c(a, b))
    })

    observeEvent(input$zoomOut, {
        t1 = ranges$xmax
        t2 = ranges$xmin
        datatable <- dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        a = max(t2 - (t1 - t2) / 2, 0)
        b = min(t1 + (t1 - t2) / 2, max)
        updateSliderInput(session, "sliderRange", value = c(a, b))
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
        for (elt in ls(datatable$objects)) {
            if (datatable$objects[[elt]]$has_data) {
                l[[elt]] = elt
            }
        }
        selectInput("object", "TDMS Object", l)
    })

    output$sliderRange <- renderUI({
        if (is.null(input$object)) {
            return()
        }
        datatable <- dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        sliderInput("sliderRange", "Range", min = 0, max = ceiling(max), value = c(ranges$xmin, ranges$xmax), step = 0.00001, width="100%", round=T)
    })

    output$distProperties <- renderPrint({
        if (is.null(input$object)) {
            return()
        }

        datatable <- dataInput()
        r = datatable$objects[['/']]
        for(prop in ls(r$properties)) {
            cat(paste(prop, ': ', r$properties[[prop]],'\n'))
        }
    })

    output$distChannel <- renderPrint({
        if (is.null(input$object)) {
            return()
        }

        datatable <- dataInput()
        r = datatable$objects[[input$object]]
        for(prop in ls(r$properties)) {
            cat(paste(prop, ': ', r$properties[[prop]],'\n'))
        }
    })


    output$distPlot <- renderPlot({
        if (is.null(input$object)) {
            return()
        }

        s = ranges$xmin
        e = ranges$xmax

        my_file = file(paste0(input$dir, '/', input$dataset), "rb")
        main = TdmsFile$new(my_file)
        main$read_data(my_file, s, e)

        r = main$objects[[input$object]]
        t = r$time_track(start = s, end = e)
        s = r$data
        close(my_file)

        plot(t, s, type = 'l', xlab = 'time', ylab = 'volts')
    })
})
