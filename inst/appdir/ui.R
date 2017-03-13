shinyUI(fluidPage(
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
))
