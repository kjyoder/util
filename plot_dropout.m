% Author: Keith Yoder (keithyoder.com)
% University of Chicago, SCNL/CNS, 8/2019

% User-defined variables
working_dir = ''; % path to files
mask_file = ''; % path to merged subject mask.nii files
sub_labels = {}; % list of subject labels
sub_thresh = 4; % threshold for reporting (e.g. up to 4th worst)

% Coordinates for the probes
xcoord = 0;
ycoord = 40;
ycoord2 = 20;
zcoord = -15;

all_masks = fullfile(working_dir, mask_file);
fprintf('Reading in %s...\n', all_masks);

% Read in the 4D mask image
V = spm_vol(all_masks);
[Y, XYZ] = spm_read_vols(V);
% extract max x, y, and z coordinates
[x y z t] = size(Y);

% convert from voxel space to mm space
XYZmm = [xcoord, ycoord, zcoord];
XYZvox = round(V(1).mat\[XYZmm 1]');

XYZmm2 = [xcoord, ycoord2, zcoord];
XYZvox2 = round(V(1).mat\[XYZmm2 1]');

fprintf('%d subjects detected. Image dim: %d x %d x %d\n',t,x,y,z);

% Plot midline image across participants
h = figure;
subplot(2,2,1)
imagesc(rot90(squeeze(mean(Y(XYZvox(1),:,:,:),4)))); 
% Set colorbar thresholds to useful value
caxis([.85 1])
colorbar
% Add coordinates to plot title
title(sprintf('Percentage of voxels present at X=%d',xcoord));
hold on
% Add probe lines
line([XYZvox(2), XYZvox(2)], [1 z], 'color', 'r');
line([XYZvox2(2), XYZvox2(2)], [1 z], 'color', 'g');
line([1 y], z-[XYZvox2(3), XYZvox2(3)],  'color', 'r');
hold off


% Plot axial image across participants
subplot(2,2,2)
imagesc(rot90(squeeze(mean(Y(:,:,XYZvox(3),:),4)))); 
caxis([.85 1])
colorbar
title(sprintf('Percentage of voxels present at Z=%d',zcoord));
hold on
line([XYZvox(1), XYZvox(1)], [1 y], 'color', 'r');
line([1 x], y-[XYZvox(2), XYZvox(2)], 'color', 'r');
line([1 x], y-[XYZvox2(2), XYZvox2(2)], 'color', 'g');
hold off

% Plot probe data
subplot(2,2,3)
% extract probe data (nsub x zvox)
probe = flipud(squeeze((Y(XYZvox(1),XYZvox(2),:,:))));
imagesc(probe); 
title(sprintf('Voxels present at X=%d, Y=%d', xcoord, ycoord));
hold on
plot([1 length(sub_labels)],[1 1],'-r');
plot([1 length(sub_labels)],[2 2],'-r');
plot([1 length(sub_labels)],[z z],'-r');
hold off
% count number of voxels for each subject within probe
probe_counts = sum(probe);
% sort values
[sval, sidx] = sort(probe_counts);
% find the worst subjects
thresh = sval(sub_thresh);
% identify any worse
worse = find(sval < thresh);
% identify any at least as bad
bad = find(sval == thresh);
low = [worse bad];
fprintf('The %d worst probe values is %d, and occur for:\n', sub_thresh, thresh);
for ii=1:length(low)
    fprintf('%s (%.0f)\n', sub_labels{sidx(low(ii))}, sval(low(ii)));
end

% Repeat with Probe 2
subplot(2,2,4)
probe = flipud(squeeze((Y(XYZvox2(1),XYZvox2(2),:,:))));
imagesc(probe); 
title(sprintf('Voxels present at X=%d, Y=%d', xcoord, ycoord2));
hold on
plot([1 length(sub_labels)],[1 1],'-g');
plot([1 length(sub_labels)],[2 2],'-g');
plot([1 length(sub_labels)],[z z],'-g');
hold off
probe_counts = sum(probe);
[sval, sidx] = sort(probe_counts);
thresh = sval(sub_thresh);
worse = find(sval < thresh);
bad = find(sval == thresh);
low = [worse bad];
fprintf('The %d worst probe values is %d, and occur for:\n', sub_thresh,thresh);
for ii=1:length(low)
    fprintf('%s (%.0f)\n', sub_labels{sidx(low(ii))}, sval(low(ii)));
end