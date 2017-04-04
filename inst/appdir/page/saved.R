library(ggplot2)
library(reshape2)

savedUI = function(id) {
    ns = NS(id)
    sidebarLayout(
        sidebarPanel(
            h2('Saved EODs'),
            p('Select one or multiple EOD selections to plot them on the same axis'),
            sliderInput(ns('windowSize'), label = 'Window size', value = 0.001, min = 0.000001, max = 0.1, step = 0.000001, width='200px'),
            actionButton(ns('deleteButton'), 'Delete selected EOD(s)'),
            actionButton(ns('deleteAll'), 'Delete all EODs'),
            checkboxInput(ns('normalize'), 'Normalize selected EOD(s)'),
            checkboxInput(ns('preBaselineSubtract'), 'Pre-normalization baseline subtract'),
            checkboxInput(ns('postBaselineSubtract'), 'Post-normalization baseline subtract'),
            checkboxInput(ns('average'), 'Average selected EOD(s)'),
            checkboxInput(ns('selectAll'), 'Select all'),
            downloadButton(ns('downloadData1'), 'Download waveform matrix'),
            downloadButton(ns('downloadData2'), 'Download average waveform'),
            actionButton(ns('analyzeWaveform'), 'Find landmarks'),
            actionButton(ns('saveLandmarks'), 'Save landmarks')
        ),
        mainPanel(
            DT::dataTableOutput(ns('table')),
            plotOutput(ns('plot'),
                click = ns('plotClick'),
                height = '700px'
            ),
            DT::dataTableOutput(ns('landmarks')),
            verbatimTextOutput(ns('stats'))
        )
    )
}
savedServer = function(input, output, session, extrainput) {
    source('page/landmark_dialog.R', local = T)

    dataMatrix = reactive({
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
            if(input$preBaselineSubtract) {
                dat = dat - mean(dat[1:25])
            }
            if(input$normalize) {
                dat = (dat - min(dat)) / (max(dat) - min(dat))
            }
            if(input$postBaselineSubtract) {
                dat = dat - mean(dat[1:25])
            }
            # rounding important here to avoid different values being collapsed. significant digits may change on sampling rate of tdms
            plotdata = rbind(plotdata, data.frame(col = ret[i, ]$start, time = round(t, digits=5), data = dat))
        }
        plotdata
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
                myplot = myplot + annotate("point", x = r['p0',]$time, y = r['p0',]$val, colour = "blue", size = 4)
                myplot = myplot + annotate("point", x = r['p1',]$time, y = r['p1',]$val, colour = "red", size = 4)
                myplot = myplot + annotate("point", x = r['p2',]$time, y = r['p2',]$val, colour = "darkgreen", size = 4)
                myplot = myplot + annotate("point", x = r['t1',]$time, y = r['t1',]$val, colour = "orange", size = 4)
                myplot = myplot + annotate("point", x = r['t2',]$time, y = r['t2',]$val, colour = "purple", size = 4)
                myplot = myplot + annotate("point", x = r['t2',]$time, y = r['t2',]$val, colour = "purple", size = 4)
                myplot = myplot + annotate("point", x = r['s1',]$time, y = r['s1',]$val, colour = "grey", size = 4)
                myplot = myplot + annotate("point", x = r['s2',]$time, y = r['s2',]$val, colour = "white", size = 4)

                output$landmarks = DT::renderDataTable(as.data.frame(r))
                output$stats = renderText(sprintf('P1-P2: %f\nT2-T1: %f', r['p1',]$val-r['p2',]$val, r['t2',]$time-r['t1',]$time))

                ret = acast(plotdata, time ~ col, value.var = 'data', fun.aggregate=mean)
                avg = apply(ret, 1, mean)
                data = data.frame(time=as.numeric(names(avg)), val=as.numeric(avg))

                baseline = mean(data$val[1:50])
                myplot = myplot + geom_hline(yintercept = baseline, color='red')
                myplot = myplot + geom_hline(yintercept = baseline+0.02*(r['p1',]$val-r['p2',]$val), color='yellow')
                myplot = myplot + geom_hline(yintercept = baseline-0.02*(r['p1',]$val-r['p2',]$val), color='green')
            }

            myplot
        })
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
            ret = acast(plotdata, time ~ col, value.var = 'data', fun.aggregate=mean)
            write.csv(ret, file, quote = F)
        }
    )

    output$downloadData2 = downloadHandler(
        filename = 'average.csv',
        content = function(file) {
            plotdata = dataMatrix()
            ret = acast(plotdata, time ~ col, value.var = 'data', fun.aggregate=mean)
            write.csv(apply(ret, 1, mean), file, quote = F)
        }
    )
    myreact = reactive({
        input$analyzeWaveform
        plotdata = dataMatrix()
        ret = acast(plotdata, time ~ col, value.var = 'data', fun.aggregate=mean)
        avg = apply(ret, 1, mean)
        data = data.frame(time=as.numeric(names(avg)), val=as.numeric(avg))
        p1pos = which.max(data$val)
        p1 = data[p1pos, ]
        p2pos = which.min(data$val)
        p2 = data[p2pos, ]
        leftside = data[1:p1pos, ]
        middle = data[p1pos:p2pos, ]
        rightside = data[p2pos:nrow(data), ]
        p0pos = which.min(leftside$val)
        p0 = data[p0pos, ]

        baseline = mean(data$val[1:25])
        t1 = NULL
        t2 = NULL
        slope1 = NULL
        slope2 = NULL
        s1 = NULL
        s2 = NULL
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
        ret = data.frame(time=numeric(0), val=numeric(0))
        ret['p0',] = p0
        ret['p1',] = p1
        ret['p2',] = p2
        ret['t1',] = t1
        ret['t2',] = t2
        ret['s1',] = s1
        ret['s2',] = s2
        ret
    })

    observeEvent(input$saveLandmarks, {
        landmarks = myreact()
        for(name in names(landmarks)) {
            val = landmarks[[name]]
            saveLandmark(name, val$time, 'peaks')
        }
    })
}

