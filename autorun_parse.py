#!/usr/bin/python3

import os
import linecache

digits = ('0','1','2','3','4','5','6','7','8','9')

mainpath = '/Users/peterkonik/Library/Mobile Documents/com~apple~CloudDocs/JOB/BNC/Guide system project/moderator_simulations/PHASAN/outfiles'
dirlist = sorted(os.listdir(mainpath)) #list of directories' names'
dirlist.remove(".DS_Store")

#list of files' paths'
filelist = [] 
for i in dirlist:
    filelist.append(mainpath + '/' + i + '/flux_at_the_end_of_chan.out')

#get n-th line with flux data, convert x3 and x2 spaces to 1x space and write to 'data'
with open('Dir_src_err0p01_TPoint_3deg','a') as datafile:
    for i in filelist:
        with open(i,'r') as outfile:
            datafile.write(linecache.getline(i, 35).replace('   ',' ').replace('  ',' '))    

