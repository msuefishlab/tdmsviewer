
helpUI = function(ui) {
    # Sidebar with a slider input for the number of bins
    sidebarLayout(
        sidebarPanel(
            h1('Help'),
            p('See the user guide on the web for more info'),
            a('https://msuefishlab.github.io/tdmsviewer')
        ),
        mainPanel(
            h2('"Home" tab'),
            p('Use the "Choose TDMS file" to select a TDMS file to record from'),
            p('The TDMS file data will be displayed in the main view subsequently'),
            p('You can click and drag your mouse directly over the plot of the electrical signal to zoom in on a region, or use the buttons and slider to move around'),
            p('Then you can configure a peak finder to either find peaks using a voltage cutoff or a statistical measure of N stddev away from mean'),
            p('Note: when zoomed out very far, the data will be downsampled to avoid excessive plotting of the data, so the peaks displayed when zoomed out may not necessarily match maximum peak values'),
            h2('"Saved EODs" tab'),
            p('The peaks that are saved from the Home tab will show up here in a table'),
            p('You can select several EODs to be plotted over each other, or check the "Select all" checkbox to display all EODs at once'),
            p('Then you can average the waveform, subtract the baseline noise away, and identify landmarks'),
            p('You can also download a csv of the matrix of the EOD signals or a single averaged EOD signal value'),
            p('After finding landmarks, a button to save them will appear at the bottom of the page'),
            h2('"Landmarks" tab'),
            p('The landmarks tab takes a set of landmarks that were identified from the "Saved EODs" tab and then analyzes that against the csv of a matrix also downloaded from the "Saved EODs" tab'),
            p('This will then generate average (mean) and deviation (dev) of all the individual EODs at the timepoints identified by the landmarks'),
            h2('Details on landmarks'),
            p('Landmarks are calculated as follows'),
            p('p0: the time that the signal is at the minimum value to the left of p1'),
            p('p1: the time that the signal is at the maximum value over the region'),
            p('p2: the time that the signal is at the minimum value of the region'),
            p('t1: the time when, walking backwards from p1, that the value is within the baseline + 2% of the peak to peak amplitude'),
            p('t2: the time when, walking forwards from p2, that the value is within the baseline - 2% of the peak to peak amplitude'),
            p('s1: the time when the slope is maximum between t1 and p1'),
            p('s2: the time when the slope is maximum(negative value) between p2 and t2')
        )
    )
}
helpServer = function(input, output, session) {
    
}

