function passEvents = reconnoiter(nReconTrials, ImagesData, baseSetsDefs, tests)
%RECONNOITER Empirically estimate test pass frequencies by random sampling.
%
%   passEvents = RECONNOITER(nReconTrials, ImagesData, baseSetsDefs, tests)
%   performs nReconTrials random draws from each base set and evaluates all
%   specified tests for each draw. It returns the number of trials in which
%   each test passed.
%
%   Inputs:
%     nReconTrials - Number of random draws to run.
%     ImagesData   - 1xN struct array; one element per image with named fields.
%     baseSetsDefs - Group definitions including required N and eligible indices.
%     tests        - 1xT cell array of test structs (see loadTestDefs).
%
%   Output:
%     passEvents   - 1xT vector; passEvents(t) is the count of draws where
%                   test t passed.
%
%   Notes:
%     - This function evaluates all tests for each draw (no early-exit).
%     - Main script converts passEvents to relative frequencies and passes
%       them for the user to estimate overall feasibility.
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


    hwait=waitbar(0,'Exploring image set...');

    nPassEvCell = cell(nReconTrials, 1); %Required for older parfor

    % Create variable values cell array from struct
    fieldsImagesData=fieldnames(ImagesData);
    varNames = fieldsImagesData(2:end);
    sizeVarNames = size(varNames,1);
    varsData=cell(sizeVarNames,1);

    % Generate cell array containing data in 1st column, variable name in 2nd
    for i = 1:size(varNames,1)
        varsData{i,1}=[ImagesData.(varNames{i})];
        varsData{i,2}=varNames{i};
    end

    % Checks feasibility of every set random selection procedures and informs user
    for i = 1:size(baseSetsDefs,1) %nrows' baseSetsDefs
        if baseSetsDefs{i,2} > length(baseSetsDefs{i,4})
            errordlg('One or more of the requested sample sizes exceeds the size of its base set. Check set parameters and sample size you requested.','Error');
        elseif baseSetsDefs{i,2} == length(baseSetsDefs{i,4})
            warndlg('One or more of the requested sample sizes equals the size of its base set. This leaves only one possible combination for this set.','Warning');
        end
    end

    for i = 1:nReconTrials
	% Begins by creating a "tape" of shuffled índices
	% Creates random set of given number of images using these indices 
	% This is done once per iteration.
    
        % Initialize selection set
        currentDrawIndices = cell(1,size(baseSetsDefs,1));
    
        % Shuffle and draw singular sets
        for j = 1:size(baseSetsDefs,1) %baseSetsDefs nrows
        
            % Shuffle indices vector and take sample of preconfigured length
            temp=randperm(length(baseSetsDefs{j,4}));
        
            % Specify drawn set by slicing base set 
            currentDrawIndices{j,1}=baseSetsDefs{j,4}(temp(1:baseSetsDefs{j,2}));
        end
    
        [ok, passedTests] = doTestingSequence(varsData, currentDrawIndices, tests, 'all');
    
        nPassEvCell{i}=passedTests;
        hwait=waitbar(i/nReconTrials,hwait); % Update waitbar.
    
    end
    close(hwait) % Close waitbar.

    % Compute pass event frequencies for later calculation of joint prob
    n_pass_ev_matrix=cell2mat(nPassEvCell);
    passEvents = sum(n_pass_ev_matrix, 1);% sum in the vertical dimension

end