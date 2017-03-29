landmarkUI = function(id) {
    ns = NS(id)
    tagList(
        selectInput(ns('landmark'), 'Landmark', c('ZC1','T1','P0','S1','P1','S2','ZC2','P2','T2')),
        numericInput(ns('time_val'), 'Time', value = input$plot_click$x),
        textInput(ns('peak_set'),  'EOD type', value = '<changeme>'),
        verbatimTextOutput(ns('txt')),
        actionButton(ns('save_landmark'), 'Save')
    )
}

landmarkServer = function(input, output, session) {
    observeEvent(input$save_landmark, {
         saveLandmark(input$landmark, input$time_val, input$peak_set)
         removeModal()
    })
}
