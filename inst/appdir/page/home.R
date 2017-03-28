
homeSidebarUI = function(id) {
    ns = NS(id)
    tagList(
        textInput(ns('tdmsfile'), 'TDMS File'),
        uiOutput(ns('objects')),
        uiOutput('TDMS file properties'),
        uiOutput(ns('distPropertiesLabel')),
        verbatimTextOutput(ns('distProperties')),
        uiOutput(ns('distChannelLabel')),
        verbatimTextOutput(ns('distChannel')),
        radioButtons(ns('threshold'), 'Threshold type:', c('Sigma' = 'sigma', 'Voltage cutoff' = 'volts')),
        radioButtons(ns('threshold_direction'), 'Threshold direction:', c('None' = 'none', 'Positive' = 'positive', 'Negative' = 'negative')),
        numericInput(ns('threshold_value'), label = 'Threshold value', value = 5)
    )
}
homeMainUI = function(id) {
    ns = NS(id)
    tagList(
        p('Zoom in/Zoom out'),
        actionButton(ns('zoomIn'), label = '+'),
        actionButton(ns('zoomOut'), label = '-'),
        actionButton(ns('moveLeft'), label = '<'),
        actionButton(ns('moveRight'), label = '>'),
        actionButton(ns('saveAll'), label = 'Save EODs in current view'),
        uiOutput(ns('sliderOutput')),
        plotOutput(ns('distPlot'),
            brush = brushOpts(
                id = ns('plot_brush'),
                resetOnNew = T,
                direction = 'x'
            )
        ),
        verbatimTextOutput(ns('txt'))
    )
}
homeServer = function(input, output, session, extrainput) {
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
        d = extrainput$file$files[[1]]
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
        sliderInput(session$ns('sliderRange'), 'Range', min = 0, max = ceiling(max), value = c(ranges$xmin, ranges$xmax), step = 0.00001, width = '100%', round = T)
    })



    output$distPlot = renderPlot({
        if (is.null(input$object)) {
            return()
        }

        s = ranges$xmin
        e = ranges$xmax

        f = input$tdmsfile
        if (!file.exists(f)) {
            return()
        }
        m = file(f, 'rb')
        main = tdmsreader::TdmsFile$new(m)
        main$read_data(m, s, e)

        r = main$objects[[input$object]]
        t = r$time_track(start = s, end = e)
        dat = r$data
        close(m)

        plot(t, dat, type = 'l', xlab = 'time', ylab = 'volts')
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

        saved_peaks = 0
        plus_peaks = 0
        minus_peaks = 0
        
        withProgress(message = 'Finding EODs', value = 0, {
            s = ranges$xmin
            e = ranges$xmax
            f = input$tdmsfile
            if (!file.exists(f)) {
                return()
            }
            m = file(f, 'rb')
            main = tdmsreader::TdmsFile$new(m)
            main$read_data(m, s, e)

            r = main$objects[[input$object]]
            t = r$time_track(start = s, end = e)
            dat = r$data

            mysd = sd(dat)
            mymean = mean(dat)
            setProgress(0.5)

            curr_time = 0
            for(i in 1:length(dat)) {
                ns = i - 1000
                ne = i + 1000
                if(i %% 100000 == 0) {
                    setProgress(i/(2*length(dat))+0.5)
                }
                if(!is.na(t[i]) & !is.na(dat[i]) & (t[i] - curr_time) > 0.001) {
                    if(input$threshold == 'sigma') {
                        if(dat[i] > mymean + mysd * input$threshold_value & (input$threshold_direction == 'none' | input$threshold_direction == 'positive')) {
                            try(saveData(t[ns + which.max(dat[ns:ne])], f, input$object, 0))
                            curr_time = t[i]
                            saved_peaks = saved_peaks + 1
                            plus_peaks = plus_peaks + 1
                        }
                        if(dat[i] < mymean - mysd * input$threshold_value & (input$threshold_direction == 'none' | input$threshold_direction == 'negative')) {
                            try(saveData(t[ns + which.min(dat[ns:ne])], f, input$object, 1))
                            curr_time = t[i]
                            saved_peaks = saved_peaks + 1
                            minus_peaks = minus_peaks + 1
                        }
                    }
                    else if(input$threshold == 'volts') {
                        if(dat[i] > input$threshold_value & (input$threshold_direction == 'none' | input$threshold_direction == 'positive')) {
                            try(saveData(t[ns + which.max(dat[ns:ne])], f, input$object, 0))
                            curr_time = t[i]
                            saved_peaks = saved_peaks + 1
                            plus_peaks = plus_peaks + 1
                        }
                        if(dat[i] < input$threshold_value & (input$threshold_direction == 'none' | input$threshold_direction == 'negative')) {
                            try(saveData(t[ns + which.min(dat[ns:ne])], f, input$object, 1))
                            curr_time = t[i]
                            saved_peaks = saved_peaks + 1
                            minus_peaks = minus_peaks + 1
                        }
                    }
                }
            }
            close(m)
        })
        output$txt <- renderText(sprintf("Saved %d peaks (%d+, %d-)", saved_peaks, plus_peaks, minus_peaks))
    })
    observe({
        reactiveValuesToList(input)
        session$doBookmark()
    })


    return (input)
}

