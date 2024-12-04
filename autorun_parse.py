#!/usr/bin/python3

import os
import linecache
import numpy as np
import csv

#name of the file to write in
filename = 'Dmp_src_btm_cls_err0p03_TPoint_10m_1+coll_laptop_OMP16'
#total number of batches used for dump file creation
N = 1e4

#path of folder 'outfiles' with data folders
mainpath = '/home/dmitrii/phits/projects/BRR/outfiles'
#list of directories' names
dirlist = sorted(os.listdir(mainpath)) 

#delete hidden directory at mac
#dirlist.remove(".DS_Store") 

#list of output files' paths
outfilelist = [] 
for i in dirlist:
    outfilelist.append(mainpath + '/' + i + '/flux_at_the_end_of_chan.out')


#get n-th line with flux data, convert x3 and x2 spaces to 1x space and write to file
with open(filename,'w') as datafile:
    for i in outfilelist:
        with open(i,'r') as outfile:
            datafile.write(linecache.getline(i, 35).replace('   ',' ').replace('  ',' '))


#list of batch files' paths
batchfilelist = [] 
for i in dirlist:
    batchfilelist.append(mainpath + '/' + i + '/batch.out')


#get number of batches
batches = []
for i in batchfilelist:
        with open(i,'r') as batchfile:
            batches.append(N - float(linecache.getline(i, 1).replace(' <--- number of remaining batches \n','')))


#get fluxes and errors from file written before
fluxes = []
errors = []
with open(filename,'r') as datafile:
    data = csv.reader(datafile, delimiter=' ')
    
    for rows in data:
        fluxes.append(float(rows[3]))
        errors.append(float(rows[4])*float(rows[3]))


#renormalize fluxes and errors to corresponding number of batches
fluxes = np.array(fluxes)*N/batches
errors = np.array(errors)*N/batches


#create 2D array and write back to the same file
fe = np.stack((fluxes, errors), axis=1)
with open(filename,'w') as datafile:
    datafile.write(str(fe).replace('[',' ').replace(']',' ').replace('  ',' '))





