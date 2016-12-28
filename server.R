library(shiny)
library(tdmsreader)

dirs = list.files('data', full.names = T)

shinyServer(function(input, output) {
  

  output$dirs <- renderUI({
    selectInput("dir", "Data group", c("Choose directory", dirs))
  })
  
  
  output$datasets <- renderUI({
    if(is.null(input$dir)) {
      return()
    }
    if(input$dir == "Choose directory") {
      return()
    }
    tdmss = list.files(input$dir, pattern = ".tdms$")
    selectInput("dataset", "TDMS File", c("Choose tdms", tdmss))
  })
  
  
  output$startTimer <- renderUI({
    if(is.null(input$dataset)) {
      return()
    }
    if(input$dataset == "Choose tdms") {
      return()
    }
    datatable<-dataInput()
    sliderInput("startTime", "Start", min=0, max=max(datatable$time), value = 0)
  })
  
  
  output$endTimer <- renderUI({
    if(is.null(input$dataset)) {
      return()
    }
    if(input$dataset == "Choose tdms") {
      return()
    }
    datatable<-dataInput()
    sliderInput("endTime", "End", min=0, max=max(datatable$time), value = 0.5)
  })
  
  
  output$fineStartTimer <- renderUI({
    if(is.null(input$endTime)) {
      return()
    }
    datatable<-dataInput()
    sliderInput("fineStartTime", "Adjust start", min=input$startTime, max=input$endTime, value = input$startTime)
  })
  
  
  output$fineEndTimer <- renderUI({
    if(is.null(input$startTime)) {
      return()
    }
    datatable<-dataInput()
    sliderInput("fineEndTime", "Adjust end", min=input$startTime, max=input$endTime, value = input$endTime)
  })
  
  output$superFineStartTimer <- renderUI({
    if(is.null(input$fineEndTime)) {
      return()
    }
    datatable<-dataInput()
    sliderInput("superFineStartTime", "Adjust start (finetune)", min=input$fineStartTime, max=input$fineEndTime, value = input$fineStartTime)
  })
  
  
  output$superFineEndTimer <- renderUI({
    if(is.null(input$fineStartTime)) {
      return()
    }
    datatable<-dataInput()
    sliderInput("superFineEndTime", "Adjust end (finetune)", min=input$fineStartTime, max=input$fineEndTime, value = input$fineEndTime)
  })
  
  dataInput <- reactive({
    withProgress(message = 'Loading...', value = 0, {
      fread(paste0(input$dir, '/', input$dataset))
    })
  })
  
  
  
  output$distPlot <- renderPlot({
    if(is.null(input$dataset)) {
      return()
    }
    if(input$dataset == "Choose tdms") {
      return()
    }

  datatable<-dataInput()

    if(is.null(input$superFineStartTime)) {
      return()
    }
    s = input$superFineStartTime
    e = input$superFineEndTime
    
    values = datatable$time > s & datatable$time < e
    plot(datatable[values,], type='l', xlab='time', ylab='volts')
  })
  


})
