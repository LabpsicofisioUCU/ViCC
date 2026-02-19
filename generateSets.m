function [final_selec, detailedStats] = generateSets(ImagesData, baseSetsDefs, tests, test_order, singleDrawsExpected)
%GENERATESETS Randomly draw candidate stimulus sets until constraints are met.
%
%   [final_selec, detailedStats] = GENERATESETS(ImagesData, baseSetsDefs, tests, ...
%       test_order, singleDrawsExpected) repeatedly samples indices from each
%   base set (group) and applies the statistical tests in the specified order.
%   The first draw that passes all tests is returned.
%
%   Inputs:
%     ImagesData          - 1xN struct array; one element per image (used to build varsData).
%     baseSetsDefs        - Group definitions including eligible indices and required N.
%     tests               - Cell array of test structs (see loadTestDefs).
%     test_order          - Order in which to evaluate tests (for early rejection).
%     singleDrawsExpected - Expected number of draws (used for progress reporting).
%
%   Outputs:
%     final_selec   - 1xG cell array; selected image indices per group.
%     detailedStats - Test statistics for the final selection (see getDetailedStats).
%
%   Notes:
%     - The search is stochastic; results depend on RNG state.
%     - Uses early-exit testing for speed (doTestingSequence with 'earlyExit').
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


    % -- Generate image sets --

    % Search granularity (tune as needed for performance)
    parBlockLength = 10;
    chunkLength = 100000;

    % Order tests for efficiency
    ordered_tests = tests(test_order);

    % Create variables cell array from struct
    fieldsImagesData=fieldnames(ImagesData);
    varNames = fieldsImagesData(2:end);
    sizeVarNames=size(varNames,1);
    varsData=cell(sizeVarNames, 1);

    % Generate cell array containing data in 1st column, variable name in 2nd
    for i = 1:size(varNames,1)
        varsData{i,1}=[ImagesData.(varNames{i})];
        varsData{i,2}=varNames{i};
    end

    % Generate sets
    hwait=waitbar(0,'Generating image sets...');

    % Enable parallel processing
    manageParallel('start') 
    
    % Compute number of expected parallel loops before finding a suiting draw
    parLoopsExpected = singleDrawsExpected/(chunkLength*parBlockLength);
    parLoopsDone = 0;

    final_selec=[]; %initialize variable where final selection is written

    tic
    while isempty(final_selec)
    	% While desired set hasnt been found yet:
        % Update waitbar
        if parLoopsDone/parLoopsExpected > 0.98
            waitbar(0.98,hwait);
        else
            waitbar(parLoopsDone/parLoopsExpected,hwait);
        end
    
        parLoopsDone = parLoopsDone+1; 
        successful_sets = cell(parBlockLength, 1);
    
        % Begin parallel processing
        parfor i = 1:parBlockLength
        
            for j = 1:chunkLength
            
                % Initialize selection set; horizontal as coded below
                currentDrawIndices = cell(size(baseSetsDefs,1),1); 
    
                % Shuffle and draw, once
                for k = 1:size(baseSetsDefs,1) %baseSetsDefs nrows
                
                    % Shuffle indices vector, take sample of preconfigured length
                    temp=randperm(length(baseSetsDefs{k,4}));
                
                    % Specify drawn set by slicing base set 
                    currentDrawIndices{k,1}=baseSetsDefs{k,4}(temp(1:baseSetsDefs{k,2}));
                end
    
                % Apply tests to the set, discarding it at the first fail event.
                [ok, ~] = doTestingSequence(varsData, currentDrawIndices, ordered_tests, 'earlyExit');
            
                % Retry until a good set is found by the testing function.
                % If one set is found, write it in the corresponding parallel
                % processing ticket row.
                if ~ok
                    continue
                else
                    successful_sets{i}=currentDrawIndices;
                    break
                end
            end    
        end
    
        disp(['Parallel processing cycles done: ' num2str(parLoopsDone)])
    
        toc
        successful_sets_werefound = ~cellfun('isempty',successful_sets); %logical: not empty
        if any(successful_sets_werefound)
            final_selec = successful_sets{find(~cellfun('isempty',successful_sets), 1)}'; %first one
        end
    
    end
    waitbar(1,hwait)
    manageParallel('close')
    close(hwait)

    disp(['Parallel processing cycles done: ' num2str(parLoopsDone)])

    disp ('Your set is ready');
    
    % Compute and write stats for the found set
    detailedStats = getDetailedStats(varsData,final_selec, tests);

end