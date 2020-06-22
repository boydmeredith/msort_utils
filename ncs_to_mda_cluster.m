function mda = ncs_to_mda_cluster(expname, ratname, sessiondate, tt, savedir)
% function ncs_to_mda_cluster(expname, ratname, sessiondate, tt, savedir)
expname
ratname
sessiondate
tt
savedir
% determine where to find the data
physdata_dir = '/jukebox/brody/physdata/';
rat_fldr = fullfile(physdata_dir,expname, ratname);
results = dir(fullfile(rat_fldr, [sessiondate, '*']));

if isempty(results)
    error('Problem finding data folder: No session found');
elseif length(results) > 1
    error('Problem finding data folder: Multiple sessions found')
end

fldr_data = fullfile(rat_fldr,results.name);
% this folder will get us mdaio stuff as well as nlx stuff
fldr_scripts = '/jukebox/brody/kjmiller/Mountainsort/Utilities';
addpath(genpath(fldr_scripts));
addpath('/usr/jtb3/code/msort_utils')

% Nlx2MatCSC_v3 is the version for Linux
fprintf(['Checking for data in: ', fldr_data,' \n', 'Loading data header... \n'])
tt_fn = @(cc) fullfile(fldr_data,['TT',tt,'_' num2str(cc) '.ncs']);
hd = Nlx2MatCSC_v3(tt_fn(1),[0,0,0,0,0],1,1)

srch_str = '-SamplingFrequency'; 
temp = find(cellfun(@isempty, strfind(hd,srch_str)) == 0);
idx  = (regexp(hd{temp},'\d'));
fs   = str2num(hd{temp}(idx));
    us_per_sample = 1e6 / fs;

%% Check everything is ok with the session timing
fprintf('Checking timing\n')
ts  = Nlx2MatCSC_v3(tt_fn(1),[1,0,0,0,0],0,1);
ts2 = Nlx2MatCSC_v3(tt_fn(2),[1,0,0,0,0],0,1);
ts3 = Nlx2MatCSC_v3(tt_fn(3),[1,0,0,0,0],0,1);
ts4 = Nlx2MatCSC_v3(tt_fn(4),[1,0,0,0,0],0,1);


if length(unique(diff(ts))) ~= 1
    warning('Timing problem! Unable to convert to mda')
end

if ~all(ts == ts2) && ~all(ts == ts3) && ~all(ts == ts4)
    warning('Timing problem! Unable to convert to mda');
end

clear ts2; clear ts3; clear ts4;

fprintf('Timing looks good!\nLoading the data\n')
%% Make the MDA
samps1  = Nlx2MatCSC_v3(tt_fn(1),[0,0,0,0,1],0,1);

n = 4;
m = numel(samps1);
mda = NaN(n,m);

mda(1,:) = samps1(:); 
fprintf('Channel 1 loaded\n')
clear samps1;

samps2 = Nlx2MatCSC_v3(tt_fn(2),[0,0,0,0,1],0,1);
mda(2,:) = samps2(:); 
fprintf('Channel 2 loaded\n')
clear samps2;

samps3 = Nlx2MatCSC_v3(tt_fn(3),[0,0,0,0,1],0,1);
mda(3,:) = samps3(:); 
fprintf('Channel 3 loaded\n')
clear samps3;

samps4 = Nlx2MatCSC_v3(tt_fn(4),[0,0,0,0,1],0,1);
mda(4,:) = samps4(:); 
fprintf('Channel 4 loaded\n')
clear samps4;

% Write the mda
fprintf('Writing MDA file\n')
tic
writemda64(mda,fullfile(savedir,[ratname, '_', sessiondate, '_TT', tt, '.mda']))
toc
fprintf('MDA file written\n')

end
