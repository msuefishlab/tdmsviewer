shiny::shinyUI(shiny::fluidPage(
    shiny::titlePanel("TDMS Viewer - Gallant Lab"),

    # Sidebar with a slider input for the number of bins
    shiny::sidebarLayout(
        shiny::sidebarPanel(
            shiny::p("Use the slider to extend range of the plot or click-and-drag your mouse over an area of the plot to zoom in"),
            shinyFiles::shinyDirButton('dir', label = 'Directory select', title = 'Please select a directory'),
            shiny::uiOutput("datasets"),
            shiny::uiOutput("objects"),
            shiny::p("TDMS file properties"),
            shiny::verbatimTextOutput("distProperties"),
            shiny::p("TDMS channel properties"),
            shiny::verbatimTextOutput("distChannel")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            p("Zoom in/Zoom out"),
            shiny::actionButton("zoomIn", label = "+"),
            shiny::actionButton("zoomOut", label = "-"),
            shiny::actionButton("moveLeft", label = "<"),
            shiny::actionButton("moveRight", label = ">"),
            shiny::uiOutput("sliderRange"),
            shiny::plotOutput("distPlot",
                brush = shiny::brushOpts(
                    id = "plot_brush",
                    resetOnNew = T,
                    direction = "x"
                )
            )
        )
    )
))
