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


    output$startTimer <- renderUI({
        if (is.null(input$object)) {
            return()
        }

        datatable <- dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        sliderInput("startTime", "Start", min = 0, max = ceiling(max), value = 0)
    })


    output$endTimer <- renderUI({
        if (is.null(input$object)) {
            return()
        }

        datatable <- dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        sliderInput("endTime", "End", min = 0, max = ceiling(max), value = 1)
    })


    output$fineStartTimer <- renderUI({
        if (is.null(input$endTime)) {
            return()
        }

        sliderInput("fineStartTime", "Adjust start", min = input$startTime, max = input$endTime, value = input$startTime)
    })


    output$fineEndTimer <- renderUI({
        if (is.null(input$startTime)) {
            return()
        }
        sliderInput("fineEndTime", "Adjust end", min = input$startTime, max = input$endTime, value = input$endTime)
    })

    output$superFineStartTimer <- renderUI({
        if (is.null(input$fineEndTime)) {
            return()
        }
        sliderInput("superFineStartTime", "Adjust start (finetune)", min = input$fineStartTime, max = input$fineEndTime, value = input$fineStartTime)
    })


    output$superFineEndTimer <- renderUI({
        if (is.null(input$fineStartTime)) {
            return()
        }
        sliderInput("superFineEndTime", "Adjust end (finetune)", min = input$fineStartTime, max = input$fineEndTime, value = input$fineEndTime)
    })




    output$distPlot <- renderPlot({
        if (is.null(input$object)) {
            return()
        }

        s = input$superFineStartTime
        e = input$superFineEndTime
        if (is.null(s) || is.null(e)) {
            return()
        }

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
