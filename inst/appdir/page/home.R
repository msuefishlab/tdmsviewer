
homeUI = function(id) {
    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            shinyFiles::shinyFilesButton(ns('file'), label = 'Choose TDMS file', title = 'Please select a TDMS file', multiple = F),
            textInput(ns('tdmsfile'), 'TDMS File'),
            uiOutput(ns('objects')),
            uiOutput('TDMS file properties'),
            uiOutput(ns('distPropertiesLabel')),
            verbatimTextOutput(ns('distProperties')),
            uiOutput(ns('distChannelLabel')),
            verbatimTextOutput(ns('distChannel')),
            radioButtons(ns('thresholdDirection'), 'Threshold direction:', c('None' = 'none', 'Positive' = 'positive', 'Negative' = 'negative')),
            numericInput(ns('thresholdValue'), label = 'Threshold value', value = 5)
        ),
        mainPanel(
            p('Zoom in/Zoom out'),
            actionButton(ns('zoomIn'), label = '+'),
            actionButton(ns('zoomOut'), label = '-'),
            actionButton(ns('moveLeft'), label = '<'),
            actionButton(ns('moveRight'), label = '>'),
            actionButton(ns('saveAll'), label = 'Save EODs in current view'),
            uiOutput(ns('sliderOutput')),
            plotOutput(ns('distPlot'),
                brush = brushOpts(
                    id = ns('plotBrush'),
                    resetOnNew = T,
                    direction = 'x'
                )
            ),
            verbatimTextOutput(ns('txt')),
            verbatimTextOutput(ns('txt2'))
        )
    )
}
homeServer = function(input, output, session) {

    shinyFiles::shinyFileChoose(input, 'file', session = session, roots = c(home = basedir))
    dataInput = reactive({
        withProgress(message = 'Loading...', value = 0, {
            f = input$tdmsfile
            if(f == '') {
                return()
            }
            m = file(f, 'rb')
            tdmsFile = tdmsreader::TdmsFile$new(m)
            close(m)
            return (tdmsFile)
        })
    })

    ranges = reactiveValues(xmin = 0, xmax = 1)

    observeEvent(input$plotBrush, {
        brush = input$plotBrush
        if (!is.null(brush)) {
            updateSliderInput(session, 'sliderRange', value = c(brush$xmin, brush$xmax))
        }
    })

    observeEvent(input$sliderRange, {
        ranges$xmin = input$sliderRange[1]
        ranges$xmax = input$sliderRange[2]
    })

    observeEvent(input$moveRight, {
        t1 = ranges$xmax
        t2 = ranges$xmin
        datatable = dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        a = max(t2 + (t1 - t2) / 2, 0)
        b = min(t1 + (t1 - t2) / 2, max)
        updateSliderInput(session, 'sliderRange', value = c(a, b))
    })
    observeEvent(input$moveLeft, {
        t1 = ranges$xmax
        t2 = ranges$xmin
        datatable = dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        a = max(t2 - (t1 - t2) / 2, 0)
        b = min(t1 - (t1 - t2) / 2, max)
        updateSliderInput(session, 'sliderRange', value = c(a, b))
    })
    observeEvent(input$zoomIn, {
        t1 = ranges$xmax
        t2 = ranges$xmin
        a = t2 + (t1 - t2) / 5
        b = t1 - (t1 - t2) / 5
        updateSliderInput(session, 'sliderRange', value = c(a, b))
    })

    observeEvent(input$zoomOut, {
        t1 = ranges$xmax
        t2 = ranges$xmin
        datatable = dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        a = max(t2 - (t1 - t2), 0)
        b = min(t1 + (t1 - t2), max)
        updateSliderInput(session, 'sliderRange', value = c(a, b))
    })

    observe({
        d = input$file$files[[1]]
        if(is.null(d)) {
            return()
        }

        f = do.call(file.path, c(basedir, d))
        updateTextInput(session, 'tdmsfile', value = f)
    })
    output$objects = renderUI({
        datatable = dataInput()
        if(is.null(datatable)) {
            return()
        }
        l = list()
        for (elt in ls(datatable$objects)) {
            if (datatable$objects[[elt]]$has_data) {
                l[[elt]] = elt
            }
        }
        selectInput(session$ns('object'), 'TDMS Object', l)
    })

    output$sliderOutput = renderUI({
        if (is.null(input$object)) {
            return()
        }
        datatable = dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        sliderInput(session$ns('sliderRange'), 'Range', min = 0, max = ceiling(max), value = c(0, 1), step = 0.00001, width = '100%', round = T)
    })



    output$distPlot = renderPlot({
        if (is.null(input$object)) {
            return()
        }
        f = input$tdmsfile
        if (!file.exists(f)) {
            return()
        }
        s = ranges$xmin
        e = ranges$xmax
        eodplotter::plotTdms(f, input$object, s, e)
    })

    output$distPropertiesLabel = renderUI({
        if (is.null(input$object)) {
            return()
        }
        p('TDMS properties')
    })
    output$distProperties = renderText({
        if (is.null(input$object)) {
            return()
        }

        datatable = dataInput()
        r = datatable$objects[['/']]

        mytext = ''
        for (prop in ls(r$properties)) {
            mytext = paste(mytext, prop, ': ', r$properties[[prop]], '\n')
        }
        mytext
    })
    output$distChannelLabel = renderUI({
        if (is.null(input$object)) {
            return()
        }
        p('TDMS channel properties')
    })

    output$distChannel = renderText({
        if (is.null(input$object)) {
            return()
        }

        datatable = dataInput()
        r = datatable$objects[[input$object]]
        mytext = ''
        for (prop in ls(r$properties)) {
            mytext = paste(mytext, prop, ': ', r$properties[[prop]], '\n')
        }
        mytext
    })

    observeEvent(input$saveAll, {
        progress <- shiny::Progress$new()
        p = eodplotter::peakFinder(filename = input$tdmsfile, channel = input$object, direction = input$direction, threshold = input$thresholdValue, start = ranges$xmin, end = ranges$xmax, progressCallback = function(val) {
            print(val)
            progress$set(val)
        })
        apply(p, 1, function(r) {
            try({
                saveData(start = r[1], inverted = r[2], file = input$tdmsfile, object = input$object)
            })
        })
    })

    observe({
        reactiveValuesToList(input)
        session$doBookmark()
    })


    return (input)
}

