library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel("TDMS Viewer - Gallant Lab"),

  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      p("Use the slider to extend range of the plot or click-and-drag your mouse over an area of the plot to zoom in"),
      uiOutput("dirs"),
      uiOutput("datasets"),
      uiOutput("objects"),
      actionButton("zoomIn", label = "+"),
      actionButton("zoomOut", label = "-")
    ),

    # Show a plot of the generated distribution
    mainPanel(
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
