
homeUI = function(id) {
    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            shinyFiles::shinyDirButton(ns('dir'), label = 'Directory select', title = 'Please select a directory'),
            uiOutput(ns('datasets')),
            uiOutput(ns('objects')),
            uiOutput('TDMS file properties'),
            uiOutput(ns('distPropertiesLabel')),
            verbatimTextOutput(ns('distProperties')),
            uiOutput(ns('distChannelLabel')),
            verbatimTextOutput(ns('distChannel'))
        ),
        mainPanel(
            p('Zoom in/Zoom out'),
            actionButton(ns('zoomIn'), label = '+'),
            actionButton(ns('zoomOut'), label = '-'),
            actionButton(ns('moveLeft'), label = '<'),
            actionButton(ns('moveRight'), label = '>'),
            actionButton(ns('saveView'), label = 'Save peak in current view'),
            actionButton(ns('saveInvertedView'), label = 'Save peak in current view (invert)'),
            uiOutput(ns('sliderOutput')),
            plotOutput(ns('distPlot'),
                brush = brushOpts(
                    id = ns('plot_brush'),
                    resetOnNew = T,
                    direction = 'x'
                )
            ),
            DT::dataTableOutput(ns('saved'))
        )
    )
}
homeServer = function(input, output, session) {
    shinyFiles::shinyDirChoose(input, session$ns('dir'), session = session, roots = c(home = basedir))

    dataInput = reactive({
        withProgress(message = 'Loading...', value = 0, {
            myDir = do.call(file.path, c(basedir, input$dir$path))
            myFilePath = file.path(myDir, input$dataset)
            if (!file.exists(myFilePath)) {
                return (NULL)
            }
            myFile = file(myFilePath, 'rb')
            tdmsFile = tdmsreader::TdmsFile$new(myFile)
            close(myFile)
            return (tdmsFile)
        })
    })

    ranges = reactiveValues(xmin = 0, xmax = 1)

    observeEvent(input$plot_brush, {
        brush = input$plot_brush
        if (!is.null(brush)) {
            updateSliderInput(session, 'sliderRange', value = c(brush$xmin, brush$xmax))
        }
    })

    observeEvent(input$sliderRange, {
        ranges$xmin = input$sliderRange[1]
        ranges$xmax = input$sliderRange[2]
    })

    observeEvent(input$moveRight, {
        if (is.null(input$dataset)) {
            return()
        }
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
        if (is.null(input$dataset)) {
            return()
        }
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
        if (is.null(input$dataset)) {
            return()
        }
        t1 = ranges$xmax
        t2 = ranges$xmin
        a = t2 + (t1 - t2) / 5
        b = t1 - (t1 - t2) / 5
        updateSliderInput(session, 'sliderRange', value = c(a, b))
    })

    observeEvent(input$zoomOut, {
        if (is.null(input$dataset)) {
            return()
        }
        t1 = ranges$xmax
        t2 = ranges$xmin
        datatable = dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        a = max(t2 - (t1 - t2), 0)
        b = min(t1 + (t1 - t2), max)
        updateSliderInput(session, 'sliderRange', value = c(a, b))
    })

    output$datasets = renderUI({
        if(is.null(input$dir)) {
            return()
        }
        myDir = do.call(file.path, c(basedir, input$dir$path))
        if (!file.exists(myDir)){
            return()
        }

        tdmss = list.files(myDir, pattern = '.tdms$')
        if (length(tdmss) == 0) {
            showModal(modalDialog('No TDMS files found in folder'))
            return()
        }
        selectInput(session$ns('dataset'), 'TDMS File', tdmss)
    })

    output$objects = renderUI({
        if (is.null(input$dataset)) {
            return()
        }
        datatable = dataInput()
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
        sliderInput(session$ns('sliderRange'), 'Range', min = 0, max = ceiling(max), value = c(ranges$xmin, ranges$xmax), step = 0.00001, width = '100%', round = T)
    })



    output$distPlot = renderPlot({
        if (is.null(input$object)) {
            return()
        }

        s = ranges$xmin
        e = ranges$xmax

        myDir = do.call(file.path, c(basedir, input$dir$path))
        myFilePath = file.path(myDir, input$dataset)
        myFile = file(myFilePath, 'rb')
        if (!file.exists(myFilePath)) {
            return()
        }
        main = tdmsreader::TdmsFile$new(myFile)
        main$read_data(myFile, s, e)

        r = main$objects[[input$object]]
        t = r$time_track(start = s, end = e)
        s = r$data
        close(myFile)

        plot(t, s, type = 'l', xlab = 'time', ylab = 'volts')
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

    observeEvent(input$saveInvertedView, {
        s = ranges$xmin
        e = ranges$xmax

        myDir = do.call(file.path, c(basedir, input$dir$path))
        myFilePath = file.path(myDir, input$dataset)
        myFile = file(myFilePath, 'rb')
        if (!file.exists(myFilePath)) {
            return()
        }
        main = tdmsreader::TdmsFile$new(myFile)
        main$read_data(myFile, s, e)

        r = main$objects[[input$object]]
        t = r$time_track(start = s, end = e)
        s = r$data
        try(saveData(t[which.min(s)], file.path(myDir, input$dataset), input$object, 1))
        close(myFile)
    })
    observeEvent(input$saveView, {
        s = ranges$xmin
        e = ranges$xmax

        myDir = do.call(file.path, c(basedir, input$dir$path))
        myFilePath = file.path(myDir, input$dataset)
        myFile = file(myFilePath, 'rb')
        if (!file.exists(myFilePath)) {
            return()
        }
        main = tdmsreader::TdmsFile$new(myFile)
        main$read_data(myFile, s, e)

        r = main$objects[[input$object]]
        t = r$time_track(start = s, end = e)
        s = r$data
        try(saveData(t[which.max(s)], file.path(myDir, input$dataset), input$object, 0))
        close(myFile)
    })

    return (input)
}

