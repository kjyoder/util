#!/usr/bin/env python
#
# report2csv.py
# Read in a report txt file from SPM xjview and create a CSV table
#
# Author: Keith Yoder (keithyoder.com)
# University of Chicago, SCNL/CNS, 2019

import sys

if len(sys.argv) < 2:
    print "Pass in a report txt file from xjview and I'll make a CSV in the same directory"
    sys.exit()
else:
    in_file = sys.argv[1]
    print "Working on %s" % in_file

f = open(in_file)
fl = f.readlines()
f.close()

for ii in range(0,len(fl)):
    # test for which style of return
    ret = '\n';
    if fl[ii][-2] == '\r':
        ret = '\n\r'
    fl[ii] = fl[ii].strip(ret)

out_file = in_file.replace('txt','csv')

out_lines = []

cluster_number = 0
voxel_count = 0
peak_x = 0
peak_y = 0
peak_z = 0
label1 = ''
label2 = ''
pval = 0
peak_T = 0
clust_thresh = 0

curline=0 # ASSERT: ignore first line (file path for stats image)

while curline < len(fl)-1:
    curline += 1

    # get the pvalue and cluster thresholds
    if 'p' in fl[curline] and 'value' in fl[curline]:
        parts = fl[curline].strip('\n').split('=')
        pval = parts[1].replace(' ','')

    if 'cluster' in fl[curline] and 'size' in fl[curline]:
        parts = fl[curline].strip('\n').split('=')
        clust_thresh = parts[1].replace(' ','')

    # ASSERT: report file follows xjView report format. Example:
    #     /labs/projects/research/fMRI/SVM_searchlight_masked_p05.nii,1
    #     Type: S
    #     df: 1
    #     Threshold
    #     -- p value = 1
    #     -- intensity = -1.633123935319537e+16
    #     -- cluster size = 10
    #     Number of clusters found: 8
    #     ----------------------
    #     Cluster 1
    #     Number of voxels: 4562
    #     Peak MNI coordinate: -46 -70  20
    #     Peak MNI coordinate region:  // Left Cerebrum // Temporal Lobe // Middle Temporal Gyrus // White Matter // undefined // Temporal_Mid_L (aal)
    #     Peak intensity: 2.2768
    
    # search for a line that begins with Cluster
    if fl[curline].startswith('Cluster'):

        # now find the relevant details and add it to the file
        while curline < len(fl) -1 and not '----' in fl[curline]:
            curline += 1
            line = fl[curline].strip('\n')

            if line.startswith('Number'):
                parts = line.strip('\n').split(':')
                voxel_count = parts[1].replace(' ','')
            elif line.startswith('Peak') and 'coordinate:' in line:
                #print ('Now getting coords: %s' % line.strip('\n'))
                parts = line.strip('\n').split(':')
                cleancoords = parts[1].replace(' ','|').replace('||','|').replace('||','|').replace('||','|').replace('||','|')
                coords = cleancoords.split('|')
                #print coords
                peak_x = coords[1]
                peak_y = coords[2]
                peak_z = coords[3]
            elif line.startswith('Peak') and 'region' in line:
                parts = line.strip('\n').split(':')
                regions = parts[1].split('//')
                label1 = regions[3]
                label2 = regions[6]
            elif line.startswith('Peak') and 'intensity' in line:
                parts = line.strip('\n').split(':')
                peak_T = parts[1].replace(' ','')
    if not peak_T == 0:
        out_lines.append(str(label1)  + ',' + str(label2) + ',' + str(peak_x) + ',' + str(peak_y) + ',' + str(peak_z) + ',' + str(voxel_count) + ',' + str(peak_T))
        peak_T = 0

out_lines.append(clust_thresh)
out_lines.append(pval)

out = open(out_file,'w')
out.write('General,Specific,X,Y,Z,k,T\n')

for line in out_lines:
    out.write('%s\n' % line)

out.close()