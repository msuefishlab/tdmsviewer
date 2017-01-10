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
        click = "plot_click",
        dblclick = dblclickOpts(
          id = "plot_dblclick"
        ),
        hover = hoverOpts(
          id = "plot_hover"
        ),
        brush = brushOpts(
          id = "plot_brush"
        )
      )
    )
  )
))
