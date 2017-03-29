landmarkUI = function(id) {
    ns = NS(id)
    tagList(
        selectInput(ns('landmark'), 'Landmark', c('ZC1','T1','P0','S1','P1','S2','ZC2','P2','T2')),
        numericInput(ns('time_val'), 'Time', value = input$plot_click$x),
        numericInput(ns('volt_val'), 'Volts', value = input$plot_click$y),
        textInput(ns('peak_set'),  'EOD type', value = '<changeme>'),
        actionButton(ns('save_landmark'), 'Save')
    )
}

landmarkServer = function(input, output, session) {
    observeEvent(input$save_landmark, {
         print(sprintf('landmark %s val %f,%f', input$landmark, input$time_val, input$volt_val))
    })
}
