library(shiny)
library(tdmsreader)
library(futile.logger)



flog.threshold(DEBUG)

# open file
shinyServer(function(input, output) {


    dataInput <- reactive({
        withProgress(message = 'Loading...', value = 0, {
            my_file = file(paste0(input$dir, '/', input$dataset), "rb")

            main <- TdmsFile$new(my_file)
            close(my_file)
            return (main)
        })
    })


    output$dirs <- renderUI({
        dirs = list.files('data', full.names = T)
        selectInput("dir", "Data group", c("Choose directory", dirs))
    })


    output$datasets <- renderUI({
        if (is.null(input$dir)) {
            return()
        }
        if (input$dir == "Choose directory") {
            return()
        }
        tdmss = list.files(input$dir, pattern = ".tdms$")
        selectInput("dataset", "TDMS File", c("Choose tdms", tdmss))
    })

    output$objects <- renderUI({
        if (is.null(input$dataset)) {
            return()
        }
        if (input$dataset == "Choose tdms") {
            return()
        }
        datatable <- dataInput()
        selectInput("object", "TDMS Object", c("Choose object", ls(datatable$objects)))
    })


    output$startTimer <- renderUI({
        if (is.null(input$object)) {
            return()
        }
        if (input$object == "Choose object") {
            return()
        }

        datatable <- dataInput()
        r = datatable$objects[[input$object]]
        t = r$time_track()
        print(min(t))
        print(max(t))

        sliderInput("startTime", "Start", min = floor(min(t)), max = ceiling(max(t)), value = 0)
    })


    output$endTimer <- renderUI({
        if (is.null(input$object)) {
            return()
        }
        if (input$object == "Choose object") {
            return()
        }


        datatable <- dataInput()
        r = datatable$objects[[input$object]]
        t = r$time_track()
        sliderInput("endTime", "End", min = min(t), max = max(t), value = 0.5)
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
        if (input$dataset == "Choose object") {
            return()
        }

        datatable <- dataInput()

        if (is.null(input$superFineStartTime)) {
            return()
        }

        s = input$superFineStartTime
        e = input$superFineEndTime

        r = datatable$objects[[input$object]]
        t = r$time_track()
        s = r$data

        plot(t[1:100], s[1:100], type = 'l', xlab = 'time', ylab = 'volts')
    })



})
