function res = save_ms_waves(expname,ratname,datestr,trodenum,brody_dir)
% input
%   expname, ratname, datestr, trodenum
% 
% output - res struct containing fields
%     event_waves 	nspikes x ntimepoints x nchannels
%     event_ind		nspikes x 1 
%     event_ts		nspikes x 1		
%     event_clus	nspikes x 1
%

sz_to_load = 1e8;

% path stuff + look for relevant ncs and mda files
kjmtnsort_dir = fullfile(brody_dir,'kjmiller/Mountainsort');
sorted_dir    = fullfile(kjmtnsort_dir,'sorted_data')
local_sorted_dir    = fullfile('\\Mac\Home\projects\long_pbups\data\phys\','sorted_data');
physdata_dir  = fullfile(brody_dir,'physdata',expname,ratname);
ncs_dir       = dir(fullfile(physdata_dir,[datestr '*']));
% if multiple directories come up for this date, assuming it's the last
% one that comes up - might be better to make it prompt the user to select
ncs_dir       = fullfile(physdata_dir, ncs_dir(end).name);

addpath(fullfile(kjmtnsort_dir, '\Utilities\mdaio'))

fn            = fullfile(sorted_dir,[ ratname '_' datestr ...
    '_TT' num2str(trodenum) '_sorted.mda']);
res_fn            = fullfile(sorted_dir,[ ratname '_' datestr ...
    '_TT' num2str(trodenum) '_mswaves.mat']);
local_res_fn = fullfile(local_sorted_dir,[ ratname '_' datestr ...
    '_TT' num2str(trodenum) '_mswaves.mat']);

dat           = readmda(fn);

% set up spike filter (hard coded params for now)
fs = 32000;
[n,f0,a0,w] = firpmord([0 1000 6000 6500]/(fs/2), [0 1 0.1], [0.01 0.06 0.01]);
spikeFilt = firpm(n,f0,a0,w,{20});

% set up time window to grab for each spike ( hard coded for now)
snip_before = 7;
snip_after  = 14;
snip_ind    = -snip_before:snip_after;

% store the data with more informative names
event_inds = dat(2,:);
event_clusters = dat(3,:);
clear dat

% relabel the cluster numbers so they are consecutive
cluster_nums = unique(event_clusters);
event_clusters_tmp = NaN(size(event_clusters));
for cluster_i = 1:length(cluster_nums)
    event_clusters_tmp(event_clusters==cluster_nums(cluster_i)) = cluster_i;
end
event_clusters = event_clusters_tmp;



% set up snip inds 
max_event_ind = max(event_inds);
sz_to_load =  round(event_inds(end)/1e8);
load_inds  = round(linspace(0,length(event_inds),3));

% set up a struct to store the results
nspikes     = length(event_inds);
ntimepoints = length(snip_ind);
nchannels   = 4;
res = struct('event_waves',nan(nspikes,ntimepoints,nchannels),...
    'event_ind', event_inds, 'event_ts', nan(nspikes,1),...
    'event_clus', event_clusters);

for ll = 1:length(load_inds)-1
    fprintf('loading chunk %i of %i...',ll,length(load_inds)-1); 
    % which event numbers are we looking at
    load_event_range = [load_inds(ll)+1 load_inds(ll+1)]
    which_events  = load_event_range(1):load_event_range(2);
    % what are the nlx indices of those event numbers
    nlx_ind_range   =  max(1,ceil(event_inds(load_event_range)/512)+[-1 1]);
    % how many entries are there here
    nrows = length(which_events);
    event_inds_corrected = event_inds(which_events) - (nlx_ind_range(1)-1)*512;
    snippet_ind = repmat(event_inds_corrected',1,ntimepoints) + ...
        repmat(snip_ind,nrows,1);
    snippet_ind(snippet_ind<1) = 1;
    for cc = 1:nchannels
        fprintf('loading data from tetrode %i channel %i\n',trodenum,cc); 
        ncs_fn = fullfile(ncs_dir, ['TT' num2str(trodenum) '_' num2str(cc), '.ncs']);
        samps  = Nlx2MatCSC(ncs_fn, [0,0,0,0,1], 0, 2, nlx_ind_range);
        samps_filt = filtfilt(spikeFilt, 1, samps(:));
        fprintf('filtering data')
        clear samps
        padded_samps_filt = samps_filt(snippet_ind);
        clear samps_filt
        padded_samps_filt(snippet_ind<1) = nan;
        res.event_waves(which_events,:,cc) = padded_samps_filt;
        clear padded_samps_filt
    end
end

try
    save(res_fn, 'res','snip_before','snip_after')
catch
    if ~exist(local_sorted_dir), mkdir(local_sorted_dir); end
    local_rat_sorted_dir = fullfile(local_sorted_dir,ratname);
    if ~exist(local_rat_sorted_dir) mkdir(local_rat_sorted_dir); end
    local_rat_sess_sorted_dir = fullfile(local_rat_sorted_dir, datestr);
    if ~exist(local_rat_sess_sorted_dir) mkdir(local_rat_sess_sorted_dir); end
    save(local_res_fn, 'res', 'snip_before', 'snip_after')
    warning('SAVING LOCALLY INSTEAD OF ON CLUSTER')
end
