#!/usr/bin/env python

import sys
from nptdms import TdmsFile
tdms_file = TdmsFile(sys.argv[1])
channel = tdms_file.object('Untitled', 'Dev1/ai0')
df = channel.as_dataframe()
df.columns = ['value']
df.index.name = 'time'
df.to_csv(sys.argv[2])
