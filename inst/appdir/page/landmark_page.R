landmarkpageUI = function(id) {

    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved landmarks'),
            p('View landmark data'),
            fileInput(ns('file2'), 'Upload EOD data', multiple = FALSE),
            actionButton(ns('refresh'), 'Refresh'),
            actionButton(ns('deleteAll'), 'Delete landmark(s)'),
            selectInput(ns('eodDescription'), 'EOD description', unique(loadLandmarks()$description))
        ),
        mainPanel(
            DT::dataTableOutput(ns('table')),
            plotOutput(ns('plotvals')),
            DT::dataTableOutput(ns('textvals')),
            uiOutput(ns('saveStats'))
        )
    )
}
landmarkpageServer = function(input, output, session, extrainput) {
    observeEvent(input$deleteAll, {
        ret = loadLandmarks()
        ret = ret[ret$description == input$eodDescription, ]

        for(i in 1:nrow(ret)) {
            r = ret[i, ]
            deleteLandmark(r$landmark, r$description)
        }
    }, priority = 1)

    output$textvals = DT::renderDataTable({
        calculatedStats()
    })

    calculatedStats = reactive({
        ret = loadLandmarks()
        ret = ret[ret$description == input$eodDescription, ]

        inFile <- input$file
        if(is.null(inFile)) {
           return ()
        }
        df = read.csv(inFile$datapath, stringsAsFactors=F)
        mytime = df$X
        df <- subset(df, select = -c(X) )

        do.call(rbind, lapply(1:nrow(ret), function(i) {
            row = ret[i, ]
            landmark_pos = which.min(abs(mytime - as.numeric(row[2])))
            r = df[landmark_pos,]
            data.frame(landmark = row$landmark, mean = mean(as.numeric(r)), sd = sd(r))
        }))
    })
    output$plotvals = renderPlot({
        ret = loadLandmarks()
        ret = ret[ret$description == input$eodDescription, ]

        inFile <- input$file
        if(is.null(inFile)) {
           return ()
        }
        df = read.csv(inFile$datapath, stringsAsFactors = F)
        mytime = df$X
        df <- subset(df, select = -c(X) )

        newdf = apply(ret, 1, function(row) {
            landmark_pos = which.min(abs(mytime - as.numeric(row[2])))
            df[landmark_pos, ]
        })
        newdf = do.call(rbind, newdf)
        newdf$landmark = ret$landmark
        newdf = melt(newdf)
        ggplot(newdf, aes(landmark, value,  color = landmark)) + geom_jitter(width = 0.1) + scale_colour_brewer(palette = "Set1")

    })

    output$table = DT::renderDataTable({
        input$deleteAll
        input$refresh
        
        ret = loadLandmarks()
        ret = ret[ret$description == input$eodDescription, ]
        ret
    })
 
    output$saveStats <- renderUI({
        if(!is.null(input$file)) {
            downloadButton(session$ns('saveStatsButton'), 'Download table (CSV)')
        }
    })

    output$saveStatsButton = downloadHandler(
        filename = 'stats.csv',
        content = function(file) {
            ret = calculatedStats()
            write.csv(ret, file, quote = F)
        }
    )
    setBookmarkExclude(
        c(
            'landmark-save_landmark',
            'landmark-time_value',
            'landmark-landmark'
        )
    )
    observe({
        extrainput$landmarkSave
        input$deleteAll
        updateSelectInput(session, 'eodDescription', choices = loadLandmarks()$description)
    })
}

