function manageParallel(action)
%MANAGEPARALLEL Configure MATLAB parallel execution for ViCC.
%
%   MANAGEPARALLEL(action) initializes or shuts down the parallel environment
%   required by ViCC. Parallel execution is needed as core set generation
%   relies on parfor loops.
%
%   The function automatically adapts to the available MATLAB version,
%   Parallel Computing Toolbox interface, and detected hardware resources.
%
%   Input:
%     action - 'start' to initialize parallel resources, 'stop' to release them.
%
%   Notes:
%     - Requires MATLAB Parallel Computing Toolbox.
%     - Behavior may differ across MATLAB releases due to pool API changes.
%
% Copyright (C) 2025 J. A. Friedl & D. Kessel
% License: GPLv3 (https://www.gnu.org/licenses/gpl-3.0.html)
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License or
% (at your option) any later version: https://www.gnu.org/licenses/
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
% GNU General Public License for more details.
%
% Repository: https://github.com/LabpsicofisioUCU/ViCC

if nargin < 1
    error('You must specify ''start'' or ''close'' as the action.');
end

switch lower(action)
    case 'start'
        if verLessThan('matlab', '8.2')  % Before R2013b requires toolbox
            % Use matlabpool with feature('numCores')
            if exist('matlabpool', 'file') == 2 && matlabpool('size') == 0
                NC = feature('numCores');
                matlabpool('open', NC);
            end

        elseif verLessThan('matlab', '8.4')  % R2013b to R2014a
            % Use parpool with parcluster for optimized worker count
            poolobj = gcp('nocreate');
            if isempty(poolobj)
                c = parcluster('local');
                parpool(c, c.NumWorkers);
            end

        else  % R2014b and newer
            % Use parpool directly with optimized worker count
            poolobj = gcp('nocreate');
            if isempty(poolobj)
                c = parcluster('local');
                parpool(c, c.NumWorkers);
            end
        end

    case 'close'
        if verLessThan('matlab', '8.4')  % Before R2014b
            if exist('matlabpool', 'file') == 2 && matlabpool('size') > 0
                matlabpool('close');
            end
        else  % R2014b and newer
            poolobj = gcp('nocreate');
            if ~isempty(poolobj)
                delete(poolobj);
            end
        end

    otherwise
        error('Invalid action. Use ''start'' or ''close''.');
end
end