import matlab.engine
import os
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from datetime import date
from datetime import datetime

wd= 'Alps_EXAMPLE_THAT_RUNS'
wd= 'Alps_2_test'
#eng = matlab.engine.start_matlab()
#os.chdir('/home/joel/src/' +wd)
#eng.clean(nargout=0)

#eng = matlab.engine.start_matlab()
#os.chdir('/home/joel/src/' +wd+ '/obs')
#eng.getfSCA_Joel(nargout=0)\

#eng = matlab.engine.start_matlab()
#os.chdir('/home/joel/src/' +wd+ '/forcing')
#eng.struct_meteo(nargout=0)

eng = matlab.engine.start_matlab()
os.chdir('/home/joel/src/' + wd)
eng.example(nargout=0)

#===============================================================================
# plot sca
#===============================================================================
print "plotting fsca"
method = 1

var = eng.workspace['SCFpo']
myarray = np.asarray(var)
myarray.shape
scfpo=myarray[0:367,method]

var = eng.workspace['SCFpri']
myarray = np.asarray(var)
myarray.shape
scfpri=myarray[0:367,method]

#var = eng.workspace['dates']
#myarray = np.asarray(var)
#myarray.shape
#month=myarray[0:367,1]

var = eng.workspace['SCFo']
scfo = np.asarray(var)
scfo=scfo.flatten()
var = eng.workspace['t']
t = np.asarray(var)
t2=t.flatten()

var = eng.workspace['to']
to = np.asarray(var)
to2=to.flatten()

d= {'date': t2, 'scfpri': scfpri,'scfpo': scfpo}
df = pd.DataFrame(data=d, index=t2)

d2= {'date': to2, 'scfo': scfo}
df2 = pd.DataFrame(data=d2, index=to2)

ax=df.plot(x='date')
myplot=df2.plot(x='date', y='scfo', ax=ax, kind='scatter')
plt.show()

outfile="fsca" +  ".png"
fig = myplot.get_figure()
fig.savefig(outfile)
#plt.close('all')

#===============================================================================
# plot swe
#===============================================================================
print "plotting swe"
# get prior and post
var = eng.workspace['Dpri']
myarray = np.asarray(var)
myarray.shape
dpri=myarray[0:367,method]

var = eng.workspace['Dpo']
myarray = np.asarray(var)
myarray.shape
dpo=myarray[0:367,method]

d= {'date': t2, 'dpri': dpri*1000,'dpo': dpo*1000}
df = pd.DataFrame(data=d, index=t2)

#read obs
df2 = pd.read_csv("/home/joel/data/GCOS/sp_5WJ.txt")
df2['DATUM'] = pd.to_datetime(df2['DATUM'], format = '%d.%m.%Y')
df2['DATUM'] = df2['DATUM'].apply(lambda x: x.toordinal())+366

ax=df.plot(x='date')
myplot=df2.plot(x='DATUM', y='SWE.mm.', ax=ax, kind='scatter')
#plt.show()

#plot
outfile="swe" +  ".png"
fig = myplot.get_figure()
fig.savefig(outfile)
#plt.close('all')





















#print date.toordinal(date())+366


#python_datetime = datetime.timedelta(days=736471 -366)+datetime.datetime(1,1,1)


#year = df["DATUM"].dt.year
#month = df["DATUM"].dt.month
#day = df["DATUM"].dt.day
#year = year.astype(int)
#month = month.astype(int)
#day = day.astype(int)
#print date.toordinal(date(year,month,day))

#datetime.fromordinal()

#from datetime import datetime as dt

#dt.strptime(df['DATUM'], "%Y-%m-%d").toordinal()




#matlab_datenum = df.date.astype(int)

#python_datetime = datetime.fromordinal(matlab_datenum) + timedelta(days=matlab_datenum%1) - timedelta(days = 366)
