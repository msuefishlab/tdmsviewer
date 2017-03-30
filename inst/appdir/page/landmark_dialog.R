landmarkUI = function(id) {
    ns = NS(id)
    tagList(
        selectInput(ns('landmark'), 'Landmark', c('ZC1','T1','P0','S1','P1','S2','ZC2','P2','T2')),
        numericInput(ns('timeVal'), 'Time', value = input$plotClick$x),
        textInput(ns('peakSet'),  'EOD type', value = '<changeme>'),
        verbatimTextOutput(ns('txt')),
        actionButton(ns('saveLandmark'), 'Save')
    )
}

landmarkServer = function(input, output, session) {
    observeEvent(input$saveLandmark, {
         saveLandmark(input$landmark, input$timeVal, input$peakSet)
         removeModal()
    })
}
