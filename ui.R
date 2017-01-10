library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel("TDMS Viewer - Gallant Lab"),

  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      uiOutput("dirs"),
      uiOutput("datasets"),
      uiOutput("objects"),
      uiOutput("sliderRange")
    ),

    # Show a plot of the generated distribution
    mainPanel(
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
