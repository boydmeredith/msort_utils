
function ncs_to_mda_cluster(expname, ratname, sessiondate, tt)
physdata_dir = '/jukebox/brody/physdata/';
rat_fldr = fullfile(physdata_dir,expname, ratname);
results = dir([rat_fldr, sessiondate, '*']);

if isempty(results)
    error('Problem finding data folder: No session found');
elseif length(results) > 1
    error('Problem finding data folder: Multiple sessions found')
end

fldr_data = [rat_fldr,results.name,'/'];
fldr_scripts = '/jukebox/brody/kjmiller/Mountainsort/';
addpath(genpath(fldr_scripts));
    

% Nlx2MatCSC_v3 is the version for Linux
fprintf(['Checking for data in: ', fldr_data,' \n', 'Loading data header... \n'])
hd = Nlx2MatCSC_v3([fldr_data,'TT', tt, '_1.ncs'],[0,0,0,0,0],1,1)

temp = strfind(hd,'-SamplingFrequency') + length(srch_str);
fs   = str2num(hd(temp-1+regexp(hd(temp:temp+10),'\d')));
    us_per_sample = 1e6 / fs;

%% Check everything is ok with the session timing
fprintf('Checking timing\n')
ts  = Nlx2MatCSC_v3([fldr_data, 'TT', tt, '_1.ncs'],[1,0,0,0,0],0,1);
ts2 = Nlx2MatCSC_v3([fldr_data, 'TT', tt, '_2.ncs'],[1,0,0,0,0],0,1);
ts3 = Nlx2MatCSC_v3([fldr_data, 'TT', tt, '_3.ncs'],[1,0,0,0,0],0,1);
ts4 = Nlx2MatCSC_v3([fldr_data, 'TT', tt, '_4.ncs'],[1,0,0,0,0],0,1);


if length(unique(diff(ts))) ~= 1
    warning('Timing problem! Unable to convert to mda')
end

if ~all(ts == ts2) && ~all(ts == ts3) && ~all(ts == ts4)
    warning('Timing problem! Unable to convert to mda');
end

clear ts2; clear ts3; clear ts4;

fprintf('Timing looks good!\nLoading the data\n')
%% Make the MDA
samps1  = Nlx2MatCSC_v3([fldr_data, 'TT', tt, '_1.ncs'],[0,0,0,0,1],0,1);

n = 4;
m = numel(samps1);
mda = NaN(n,m);

mda(1,:) = samps1(:); 
fprintf('Channel 1 loaded\n')
clear samps1;

samps2 = Nlx2MatCSC_v3([fldr_data, 'TT', tt, '_2.ncs'],[0,0,0,0,1],0,1);
mda(2,:) = samps2(:); 
fprintf('Channel 2 loaded\n')
clear samps2;

samps3 = Nlx2MatCSC_v3([fldr_data, 'TT', tt, '_3.ncs'],[0,0,0,0,1],0,1);
mda(3,:) = samps3(:); 
fprintf('Channel 3 loaded\n')
clear samps3;

samps4 = Nlx2MatCSC_v3([fldr_data, 'TT', tt, '_4.ncs'],[0,0,0,0,1],0,1);
mda(4,:) = samps4(:); 
fprintf('Channel 4 loaded\n')
clear samps4;

% Write the mda
fprintf('Writing MDA file\n')
writemda64(mda,[fldr_scripts,'/tmp/tmp_', ratname, '_', sessiondate, '/', ratname, '_', sessiondate, '_TT', tt, '.mda'])
fprintf('MDA file written\n')
clear mda

end