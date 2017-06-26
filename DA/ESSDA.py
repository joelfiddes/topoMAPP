import matlab.engine
import os

wd= 'Alps_2'
# eng = matlab.engine.start_matlab()
# os.chdir('/home/joel/src/' +wd)
# eng.clean(nargout=0)

# eng = matlab.engine.start_matlab()
# os.chdir('/home/joel/src/' +wd+ '/obs')
# eng.getfSCA_Joel(nargout=0)\

# eng = matlab.engine.start_matlab()
# os.chdir('/home/joel/src/' +wd+ '/forcing')
# eng.struct_meteo(nargout=0)

eng = matlab.engine.start_matlab()
os.chdir('/home/joel/src/' + wd)
eng.example(nargout=0)


method = 1

import numpy as np
var = eng.workspace['SCFpo']
myarray = np.asarray(var)
myarray.shape
scfpo=myarray[0:367,method]

var = eng.workspace['SCFpri']
myarray = np.asarray(var)
myarray.shape
scfpri=myarray[0:367,method]

var = eng.workspace['dates']
myarray = np.asarray(var)
myarray.shape
month=myarray[0:367,1]

var = eng.workspace['SCFo']
scfo = np.asarray(var)
var = eng.workspace['t']
t = np.asarray(var)
t2=t.flatten()

var = eng.workspace['to']
to = np.asarray(var)

#import matplotlib
import matplotlib.pyplot as plt
#matplotlib.use('Agg')
import pandas as pd
d = {'date': t2, 'scfpo': scfpo, 'month':month}
df = pd.DataFrame(data=d)

d = {'date': t2, 'scfpri': scfpri, 'month':month}
df2 = pd.DataFrame(data=d)

ax=df.plot(x='date', y='scfpo' , xlim=(200,350))

myplot=df2.plot(x='date', y='scfpri',ax=ax)
plt.show()
outfile="plot" +  ".png"
fig = myplot.get_figure()
fig.savefig(outfile)
#plt.close('all')


