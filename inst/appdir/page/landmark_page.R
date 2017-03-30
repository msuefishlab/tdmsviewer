landmarkpageUI = function(id) {

    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved landmarks'),
            p('View landmark data'),
            fileInput(ns('file'), 'Upload EOD data', multiple = FALSE),
            actionButton(ns('refresh'), 'Refresh'),
            actionButton(ns('deleteAll'), 'Delete landmark(s)'),
            selectInput(ns('eodDescription'), 'EOD description', unique(loadLandmarks()$description))
        ),
        mainPanel(
            DT::dataTableOutput(ns('table')),
            plotOutput(ns('plotvals')),
            verbatimTextOutput(ns('textvals'))
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

    output$textvals = renderText({
        ret = loadLandmarks()
        ret = ret[ret$description == input$eodDescription, ]

        inFile <- input$file
        if(is.null(inFile)) {
           return ()
        }
        df = read.csv(inFile$datapath, stringsAsFactors=F)
        mytime = df$X
        df <- subset(df, select = -c(X) )

        newdf = apply(ret, 1, function(row) {
            landmark_pos = which.min(abs(mytime - as.numeric(row[2])))
            df[landmark_pos,]
        })
        newdf = do.call(rbind, newdf)
        ret = lapply(1:nrow(newdf), function(i) {
            sprintf('Output %s: val %f (sd %f)', ret[i, ]$landmark, mean(as.numeric(newdf[i, ])), sd(newdf[i, ]))
        })
        paste0(ret, collapse = '\n')
    })
    output$plotvals = renderPlot({
        ret = loadLandmarks()
        ret = ret[ret$description == input$eodDescription, ]

        inFile <- input$file
        if(is.null(inFile)) {
           return ()
        }
        df = read.csv(inFile$datapath, stringsAsFactors=F)
        mytime = df$X
        df <- subset(df, select = -c(X) )

        newdf = apply(ret, 1, function(row) {
            landmark_pos = which.min(abs(mytime - as.numeric(row[2])))
            df[landmark_pos,]
        })
        newdf = do.call(rbind, newdf)
        newdf$landmark = ret$landmark
        newdf = melt(newdf)
        ggplot(newdf, aes(landmark, value,  fill = landmark)) + geom_jitter(width = 0.1, height = 0.1)

    })

    output$table = DT::renderDataTable({
        input$deleteAll
        input$refresh
        
        ret = loadLandmarks()
        ret = ret[ret$description == input$eodDescription, ]
        ret
    })

}

