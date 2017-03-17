
helpUI = function(ui) {
    # Sidebar with a slider input for the number of bins
    sidebarLayout(
        sidebarPanel(
            p('Use the slider to extend range of the plot or click-and-drag your mouse over an area of the plot to zoom in')
        ),
        mainPanel()
    )
}
helpServer = function(input, output, session) {
    
}

