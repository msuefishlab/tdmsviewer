library(ggplot2)
library(reshape2)

savedUI = function(id) {
    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved EODs'),
            p('Select one or multiple EOD selections to plot them on the same axis'),
            sliderInput(ns('windowSize'), label = 'Window size', value = 0.005, min = 0.000001, max = 0.1, step = 0.000001, width='200px'),
            actionButton(ns('deleteButton'), 'Delete selected EOD(s)'),
            actionButton(ns('deleteAll'), 'Delete all EODs'),
            checkboxInput(ns('normalize'), 'Normalize selected EOD(s)'),
            checkboxInput(ns('preBaselineSubtract'), 'Pre-normalization baseline subtract'),
            checkboxInput(ns('postBaselineSubtract'), 'Post-normalization baseline subtract'),
            checkboxInput(ns('average'), 'Average selected EOD(s)'),
            checkboxInput(ns('selectAll'), 'Select all'),
            checkboxInput(ns('drawTwoPercent'), 'Draw 2% lines'),
            downloadButton(ns('downloadData1'), 'Download waveform matrix'),
            downloadButton(ns('downloadData2'), 'Download average waveform'),
            actionButton(ns('analyzeWaveform'), 'Find landmarks')
        ),
        mainPanel(
            DT::dataTableOutput(ns('table')),
            plotOutput(ns('plot'),
                click = ns('plotClick'),
                height = '700px'
            ),
            DT::dataTableOutput(ns('landmarks')),
            verbatimTextOutput(ns('stats')),
            verbatimTextOutput(ns('saved')),
            uiOutput(ns('saveLandmarks'))
        )
    )
}
savedServer = function(input, output, session, extrainput) {
    dataMatrixPre = reactive({
        if(!input$selectAll && is.null(input$table_rows_selected)) {
            return()
        }
        input$deleteButton
        input$deleteAll
        extrainput$saveAll
        
        ret = loadData()

        if(input$selectAll) {
            ret = ret[input$table_rows_all, ]
        } else {
            ret = ret[input$table_rows_selected, ]
        }

        vec = NULL
        t = numeric(0)
        plotdata = data.frame(col = numeric(0), time = numeric(0), dat = numeric(0))
 
        for(i in 1:nrow(ret)) {
            s = ret[i, ]$start - input$windowSize / 2
            e = ret[i, ]$start + input$windowSize / 2

            myFilePath = ret[i, ]$file
            if(is.na(myFilePath)) {
                return()
            }
            myFile = file(myFilePath, 'rb')
            if (!file.exists(myFilePath)) {
                return()
            }
            main = tdmsreader::TdmsFile$new(myFile)
            main$read_data(myFile, s, e)

            r = main$objects[[ret[i, ]$object]]
            t = r$time_track(start = s, end = e)
            t = t - ret[i, ]$start
            dat = r$data
            close(myFile)
            if(ret[i, ]$inverted) {
                dat = -dat
            }

            # rounding important here to avoid different values being collapsed. significant digits may change on sampling rate of tdms
            plotdata = rbind(plotdata, data.frame(col = ret[i, ]$start, time = round(t, digits=5), data = dat))
        }
        plotdata
    })
    dataMatrix = reactive({
        ret = dataMatrixPre()

        for(i in unique(ret$col)) {
            dat = ret[ret$col == i, ]$data
            if(input$preBaselineSubtract) {
                dat = dat - mean(dat[1:25])
            }
            if(input$normalize) {
                dat = (dat - min(dat)) / (max(dat) - min(dat))
            }
            if(input$postBaselineSubtract) {
                dat = dat - mean(dat[1:25])
            }
            ret[ret$col == i, ]$data = dat
        }
        ret
    })

    output$table = DT::renderDataTable({
        input$deleteButton
        input$deleteAll
        extrainput$saveAll
        loadData()
    })

    output$plot = renderPlot({
        withProgress(message = 'Loading EODs', {
            plotdata = dataMatrix()
            if(is.null(plotdata)) {
                return()
            }

            if(input$average) {
                myplot = ggplot(data=plotdata, aes(x=time, y=data)) + stat_summary(aes(y = data), fun.y=mean, geom='line')
            } else {
                myplot = ggplot(data=plotdata, aes(x=time, y=data, group=col)) + geom_line()
            }

            if(input$analyzeWaveform) {
                r = myreact()
                myplot = myplot + geom_point(data = r, aes(x=time, y=val, color=landmark), size = 4) + scale_colour_brewer(palette = "Set1")

                output$landmarks = DT::renderDataTable(r)
                output$stats = renderText(sprintf('P1-P2: %f\nT2-T1: %f',
                    r[r$landmark=='p1',]$val - r[r$landmark=='p2',]$val,
                    r[r$landmark=='t2',]$time - r[r$landmark=='t1',]$time)
                )


                if(input$drawTwoPercent) {
                    ret = acast(plotdata, time ~ col, value.var = 'data', fun.aggregate = mean)
                    avg = apply(ret, 1, mean)
                    data = data.frame(time=as.numeric(names(avg)), val=as.numeric(avg))

                    baseline = mean(data$val[1:50])
                    myplot = myplot + geom_hline(yintercept = baseline, color = 'red')
                    myplot = myplot + geom_hline(yintercept = baseline + 0.02 * (r[r$landmark=='p1',]$val - r[r$landmark=='p2',]$val), color = 'yellow')
                    myplot = myplot + geom_hline(yintercept = baseline - 0.02 * (r[r$landmark=='p1',]$val - r[r$landmark=='p2',]$val), color = 'green')
                }
            }

            myplot
        })
    })

    
    output$saveLandmarks <- renderUI({
        if(input$analyzeWaveform) {
            actionButton(session$ns('saveLandmarksButton'), 'Save landmarks')
        }
    })

    observeEvent(input$deleteButton, {
        ret = loadData()
        ret = ret[input$table_rows_selected, ]
        for(i in 1:nrow(ret)) {
            deleteData(ret[i, ]$start, ret[i, ]$file, ret[i, ]$object)
        }
    }, priority = 1)

    observeEvent(input$deleteAll, {
        ret = loadData()
        ret = ret[input$table_rows_all, ]
        for(i in 1:nrow(ret)) {
            r = ret[i, ]
            deleteData(r$start, r$file, r$object)
        }
    }, priority = 1)

    observe({
        reactiveValuesToList(input)
        session$doBookmark()
    })


    output$downloadData1 = downloadHandler(
        filename = 'matrix.csv',
        content = function(file) {
            plotdata = dataMatrix()
            ret = acast(plotdata, time ~ col, value.var = 'data', fun.aggregate = mean)
            write.csv(ret, file, quote = F)
        }
    )

    output$downloadData2 = downloadHandler(
        filename = 'average.csv',
        content = function(file) {
            plotdata = dataMatrix()
            ret = acast(plotdata, time ~ col, value.var = 'data', fun.aggregate = mean)
            write.csv(apply(ret, 1, mean), file, quote = F)
        }
    )
    myreact = reactive({
        input$analyzeWaveform
        plotdata = dataMatrix()
        ret = acast(plotdata, time ~ col, value.var = 'data', fun.aggregate = mean)
        avg = apply(ret, 1, mean)
        data = data.frame(time = as.numeric(names(avg)), val = as.numeric(avg))
        p1pos = which.max(data$val)
        p1 = data[p1pos, ]
        p2pos = which.min(data$val)
        p2 = data[p2pos, ]
        leftside = data[1:p1pos, ]
        middle = data[p1pos:p2pos, ]
        rightside = data[p2pos:nrow(data), ]

        baseline = mean(data$val[1:25])
        p0 = NULL
        t1 = NULL
        t2 = NULL
        slope1 = NULL
        slope2 = NULL
        s1 = NULL
        s2 = NULL
        zc1 = NULL
        zc2 = NULL
        for(i in nrow(leftside):1) {
            if(leftside[i, 'val'] < baseline) {
                zc1 = leftside[i,]
                tzc1 = zc1$time
                p0calculator = leftside[leftside$time >= tzc1-0.0005 & leftside$time <= tzc1,]
                p0 = p0calculator[which.min(p0calculator$val), ]
                break
            }
        }
        for(i in nrow(leftside):1) {
            if(leftside[i, 'val'] < baseline + 0.02 * (p1$val - p2$val)) {
                t1 = leftside[i,]
                slope1 = leftside[i:nrow(leftside), ]
                break
            }
        }
        for(i in 1:nrow(rightside)) {
            if(rightside[i, 'val'] > baseline - 0.02 * (p1$val - p2$val)) {
                t2 = rightside[i,]
                break
            }
        }

        slope1_max = -100000
        for(i in 1:(nrow(slope1)-1)) {
            s = (slope1[i+1, 'val'] - slope1[i, 'val']) / (slope1[i+1, 'time'] - slope1[i, 'time'])
            if(s > slope1_max) {
                slope1_max = s
                s1 = slope1[i,]
            }
        }
        slope2_max = 100000
        for(i in 1:(nrow(middle)-1)) {
            s = (middle[i+1, 'val'] - middle[i, 'val']) / (middle[i+1, 'time'] - middle[i, 'time'])
            if(s < slope2_max) {
                slope2_max = s
                s2 = middle[i, ]
            }
        }
        for(i in 1:nrow(middle)) {
            if(middle[i, 'val'] < baseline) {
                zc2 = middle[i,]
                break
            }
        }



        ret = data.frame(landmark = 'p0', time = p0$time, val = p0$val)
        ret = rbind(ret, data.frame(landmark = 'p1', time = p1$time, val = p1$val))
        ret = rbind(ret, data.frame(landmark = 'p2', time = p2$time, val = p2$val))
        ret = rbind(ret, data.frame(landmark = 't1', time = t1$time, val = t1$val))
        ret = rbind(ret, data.frame(landmark = 't2', time = t2$time, val = t2$val))
        ret = rbind(ret, data.frame(landmark = 's1', time = s1$time, val = s1$val))
        ret = rbind(ret, data.frame(landmark = 's2', time = s2$time, val = s2$val))
        ret = rbind(ret, data.frame(landmark = 'zc1', time = zc1$time, val = zc1$val))
        ret = rbind(ret, data.frame(landmark = 'zc2', time = zc2$time, val = zc2$val))
        ret
    })

    observeEvent(input$saveLandmarksButton, {
        showModal(modalDialog(
            title = 'Create name for landmark set',
            easyClose = T,
            tagList(
                textInput(session$ns('landmarkSet'), 'Landmark set ID'),
                actionButton(session$ns('landmarkSave'), 'Save')
            )
        ))
        
    })
    observeEvent(input$landmarkSave, {
        removeModal()
        landmarks = myreact()
        for(i in 1:nrow(landmarks)) {
            val = landmarks[i, ]
            try(saveLandmark(val$landmark, val$time, input$landmarkSet))
        }
        output$saved <- renderText(sprintf('Saved %d landmarks', nrow(landmarks)))
    })

    return (input)
}

