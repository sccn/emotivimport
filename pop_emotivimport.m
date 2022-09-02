% pop_emotivimport() - import data from Emotiv CSV files
%
% Usage:
%   >> [EEG, com] = pop_emotivimport; % pop-up window mode
%   >> [EEG, com] = pop_emotivimport(filename);
%
% Optional inputs:
%   filename  - name of Muse Monitor .csv file
%
% Outputs:
%   EEG       - EEGLAB EEG structure
%   com       - history string
%
% Author: Arnaud Delorme, 2022-

% Copyright (C) 2022 Arnaud Delorme, arno@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Id: pop_loadbv.m 53 2010-05-22 21:57:38Z arnodelorme $
% Revision 1.5 2010/03/23 21:19:52 roy
% added some lines so that the function can deal with the space lines in the ASCII multiplexed data file

function [EEG, com] = pop_emotivimport(fileName)

com = '';
EEG = [];

if nargin < 1
    [fileName, filePath] = uigetfile2({ '*.csv' '*.CSV' }, 'Select Emotiv .csv file - pop_emotivimport()');
    if fileName(1) == 0, return; end
    fileName = fullfile(filePath, fileName);
else
    options = varargin;
end

M = importdata(fileName, ',');

headerNames = strsplit(M.textdata{1}, ',');

sRate = 128;
setName = '';
for iItem = 1:length(headerNames)
    if contains(headerNames{iItem}, 'title:')
        posColon = find(headerNames{iItem} == ':');
        setName = headerNames{iItem} (posColon+1:end);
    end
    if contains(headerNames{iItem}, 'eeg_')
        posEEG = find(headerNames{iItem} == ':');
        sRate = str2double(headerNames{iItem} (posEEG+5:posEEG+7));
        if isnan(sRate) || sRate == 0
            sRate = 128;
        end
    end
end

% import only EEG columns
count = 1;
colInd = [];
chanNames = {};
for iCol = 1:length(M.colheaders)
    if contains(M.colheaders{iCol}, 'EEG.') && ~isequal(M.colheaders{iCol},'EEG.Counter') && ~isequal(M.colheaders{iCol},'EEG.Interpolated')
        chanNames{count} = M.colheaders{iCol}(5:end);
        colInd = [ colInd iCol ];
        count = count+1;
    end
end

EEG = eeg_emptyset;
EEG.setname = setName;
EEG.data = M.data(:,colInd)';
EEG.chanlocs = struct('labels', chanNames);
eeglabp = fileparts(which('eeglab.m'));
EEG.pnts   = size(EEG.data,2);
EEG.nbchan = size(EEG.data,1);

EEG.xmin = 0;
EEG.trials = 1;
EEG.srate = sRate;
EEG = eeg_checkset(EEG);
EEG=pop_chanedit(EEG, 'lookup',fullfile(eeglabp, 'plugins','dipfit','standard_BEM','elec','standard_1005.elc'));

com = sprintf('EEG = pop_emotivimport(''%s'');', fileName);
