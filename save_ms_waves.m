function save_ms_waves(expname,ratname,datestr,trodenum)
% input
%   expname, ratname, datestr, trodenum
% output - res struct containing fields
%     event_waves 	nspikes x ntimepoints x nchannels
%     event_ind		nspikes x 1 
%     event_ts		nspikes x 1		
%     event_clus	nspikes x 1
%
% 

res = struct('event_waves',nan(nspikes,ntimepoints,nchannels),...
    'event_ind',nan(nspikes,1), 'event_ts',nan(nspikes,1),...
    'event_clus', nan(spikes,1));


