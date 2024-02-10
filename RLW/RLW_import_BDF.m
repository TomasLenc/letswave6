function [out_header,out_data,message_string]=RLW_import_BDF(filename, varargin)
%RLW_import_BDF
%
%Import BDF data
%filename : name of BDF file 
%
% Author : 
% Andre Mouraux
% Institute of Neurosciences (IONS)
% Universite catholique de louvain (UCL)
% Belgium
% 
% Contact : andre.mouraux@uclouvain.be
% This function is part of Letswave 6
% See http://nocions.webnode.com/letswave for additional information
%

parser = inputParser;

addParameter(parser, 'chan_labels', {});

parse(parser, varargin{:});

chan_labels = parser.Results.chan_labels;


message_string={};
out_header=[];
out_data=[];

message_string{1}=['Loading : ' filename];

%load header
hdr=ft_read_header(filename);

% find requested channels 
if isempty(chan_labels)
    chan_idx = [1 : length(hdr.label)]; 
else
    chan_idx = find(ismember(hdr.label, chan_labels)); 
    if length(chan_idx) ~= length(chan_labels)
        error('could not find all requested channel names in the BDF header...'); 
    end
end
% update header 
hdr.nChans = length(chan_idx); 
hdr.label = hdr.label(chan_idx); 
hdr.chantype = hdr.chantype(chan_idx); 
hdr.chanunit = hdr.chanunit(chan_idx); 

%load the BDF file
%load data
dat=ft_read_data(filename, 'chanindx', chan_idx);

%load events
trg=ft_read_event(filename);

[p,n,e]=fileparts(filename);

%set header
message_string{end+1}='Creating header';
out_header.filetype='time_amplitude';
out_header.name=n;
out_header.tags='';
out_header.history=[];
out_header.datasize=[hdr.nTrials hdr.nChans 1 1 1 hdr.nSamples];
out_header.xstart=(hdr.nSamplesPre/hdr.Fs)*-1;
out_header.ystart=0;
out_header.zstart=0;
out_header.xstep=1/hdr.Fs;
out_header.ystep=1;
out_header.zstep=1;

%set chanlocs
message_string{end+1}=['Importing ',num2str(hdr.nChans),' channel labels'];
%dummy chanloc
chanloc.labels='';
chanloc.topo_enabled=0;
chanloc.SEEG_enabled=0;
%set chanlocs
for chanpos=1:hdr.nChans;
    chanloc.labels=hdr.label{chanpos};
    out_header.chanlocs(chanpos)=chanloc;
end;

%set events
numevents=size(trg,2);
message_string{end+1}=['Importing ',num2str(numevents),' events'];
if numevents==0;
    out_header.events=[];
else
    for eventpos=1:numevents;
        event.code='unknown';
        if isempty(trg(eventpos).value);
            event.code=trg(eventpos).type;
        else
            event.code=trg(eventpos).value;
        end;
        if isnumeric(event.code);
            event.code=num2str(event.code);
        end;
        event.latency=(trg(eventpos).sample*out_header.xstep)+out_header.xstart;
        event.epoch=1;
        out_header.events(eventpos)=event;
    end;
end;

%set data
message_string{end+1}=['Importing data (',num2str(hdr.nSamples),' samples, ',num2str(hdr.nTrials),' trial(s))'];
out_data=zeros(out_header.datasize);
for chanpos=1:out_header.datasize(2);
    for epochpos=1:out_header.datasize(1);
        out_data(epochpos,chanpos,1,1,1,:)=squeeze(dat(chanpos,:,epochpos));
    end;
end;
