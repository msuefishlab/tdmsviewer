ui = function() {
    fluidPage(
        titlePanel("TDMS Viewer - Gallant Lab"),

        # Sidebar with a slider input for the number of bins
        sidebarLayout(
            sidebarPanel(
                p("Use the slider to extend range of the plot or click-and-drag your mouse over an area of the plot to zoom in"),
                shinyFiles::shinyDirButton('dir', label = 'Directory select', title = 'Please select a directory'),
                uiOutput("datasets"),
                uiOutput("objects"),
                p("TDMS file properties"),
                verbatimTextOutput("distProperties"),
                p("TDMS channel properties"),
                verbatimTextOutput("distChannel")
            ),

            # Show a plot of the generated distribution
            mainPanel(
                p("Zoom in/Zoom out"),
                actionButton("zoomIn", label = "+"),
                actionButton("zoomOut", label = "-"),
                actionButton("moveLeft", label = "<"),
                actionButton("moveRight", label = ">"),
                uiOutput("sliderRange"),
                plotOutput("distPlot",
                    brush = brushOpts(
                        id = "plot_brush",
                        resetOnNew = T,
                        direction = "x"
                    )
                )
            )
        )
    )
}
server = function(input, output, session) {
    shinyFiles::shinyDirChoose(input, 'dir', session = session, roots = c(home = basedir))

    dataInput = reactive({
        withProgress(message = 'Loading...', value = 0, {
            myDir = do.call(file.path, c(basedir, input$dir$path))
            myFilePath = file.path(myDir, input$dataset)
            if (!file.exists(myFilePath)) {
                return (NULL)
            }
            myFile = file(myFilePath, "rb")
            tdmsFile = tdmsreader::TdmsFile$new(myFile)
            close(myFile)
            return (tdmsFile)
        })
    })

    ranges = reactiveValues(xmin = 0, xmax = 1)

    observeEvent(input$plot_brush, {
        brush = input$plot_brush
        if (!is.null(brush)) {
            updateSliderInput(session, "sliderRange", value = c(brush$xmin, brush$xmax))
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
        updateSliderInput(session, "sliderRange", value = c(a, b))
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
        updateSliderInput(session, "sliderRange", value = c(a, b))
    })
    observeEvent(input$zoomIn, {
        if (is.null(input$dataset)) {
            return()
        }
        t1 = ranges$xmax
        t2 = ranges$xmin
        a = t2 + (t1 - t2) / 3
        b = t1 - (t1 - t2) / 3
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
        a = max(t2 - (t1 - t2) / 2, 0)
        b = min(t1 + (t1 - t2) / 2, max)
        updateSliderInput(session, "sliderRange", value = c(a, b))
    })

    output$datasets = renderUI({
        print(input$dir)
        myDir = do.call(file.path, c(basedir, input$dir$path))
        if (!file.exists(myDir)){
            return()
        }

        tdmss = list.files(myDir, pattern = ".tdms$")
        if (length(tdmss) == 0) {
            showModal(modalDialog("No TDMS files found in folder"))
            return()
        }
        selectInput("dataset", "TDMS File", tdmss)
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
        selectInput("object", "TDMS Object", l)
    })

    output$sliderRange = renderUI({
        if (is.null(input$object)) {
            return()
        }
        datatable = dataInput()
        r = datatable$objects[[input$object]]
        max = r$number_values * r$properties[['wf_increment']]
        sliderInput("sliderRange", "Range", min = 0, max = ceiling(max), value = c(ranges$xmin, ranges$xmax), step = 0.00001, width = "100%", round = T)
    })



    output$distPlot = renderPlot({
        if (is.null(input$object)) {
            return()
        }

        s = ranges$xmin
        e = ranges$xmax

        myDir = do.call(file.path, c(basedir, input$dir$path))
        myFilePath = file.path(myDir, input$dataset)
        myFile = file(myFilePath, "rb")
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

    observeEvent(input$dir, {
        print('here')
        session$doBookmark()
    })

    onBookmarked(function(url) {
        updateQueryString(url)
    })
}

shinyApp(ui = ui, server = server, enableBookmarking = "url")
