function [tests, testDescriptions] = loadTestDefs(groupNames,testDefPath,testDefFile)
%LOADTESTDEFS Load statistical test definitions from CSV.
%
%   [tests, testDescriptions] = LOADTESTDEFS(groupNames, testDefPath, testDefFile)
%   reads a test definition CSV (e.g., testdefs.csv) and returns a cell array of
%   test configuration structs used by ViCC and a cell array describing those tests.
%
%   Each row defines:
%     - test type ('ttest2' or 'anova1')
%     - variable name (must match a field in ImagesData / varsData)
%     - groups to compare (by group name)
%     - operator and threshold applied to the p-value (e.g., p > 0.2 or p < 0.05)
%
%   Inputs:
%     groupNames  - 1xG cell array of group names (as defined in basesets.csv).
%     testDefPath - Folder containing the test definition CSV.
%     testDefFile - CSV filename.
%
%   Output:
%     tests - 1xT cell array of structs with fields: type, var, groups, op, thresh
%     testDescriptions - 1xT cell array of test descriptions in English
%
%   Notes:
%     - Group names in the CSV must match groupNames (case-sensitive).
%     - The p-value rule encodes similarity (p > alpha) or required difference (p < alpha).
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

    
    fid = fopen(fullfile(testDefPath,testDefFile)); % Open test defs csv
    defsText = textscan(fid, '%s%s%s%s%n', 'Delimiter',';', 'Whitespace',' ', 'Headerlines',1);
    fclose(fid);
    
    
    % -- Generate definitions -- 
    nDefs = size(defsText{1},1); % Number of definition text rows (from inside cell)
    tests=cell(nDefs,1); % Initialize definitions array
    tdfields = {'type','var','groups','op','thresh'}; % Test definition fields
    
    % Initialize description lines
    testDescriptions = cell(nDefs,1);
    
    for i = 1:nDefs
       
        td = struct(); % Initialize
    
        for j = 1:length(tdfields) % Horizontal dimension
    
            if strcmp(tdfields{j},'groups') % Special treatment for groups label to numbers

                groupsStrings=regexp(defsText{j}{i}, ',', 'split'); % Parses groups string
                groupsIndices=NaN(size(groupsStrings)); % Initializes indices vector
                for k = 1:length(groupsStrings) % For every group...
                    groupsIndices(k)= find(strcmp(groupNames, groupsStrings(k))); % Identify group indices from dict
                end
                td.(tdfields{j})=groupsIndices; % Writes group indices
        
            elseif strcmp(tdfields{j},'thresh')
               
                td.(tdfields{j})=defsText{j}(i); % Writes threshold value (numeric)
        
            else
                td.(tdfields{j})=defsText{j}{i}; % Write other type cell content
        
            end
            
        end
    
        tests{i,1}=td; % Writes struct in corresponding row, first col
        
        % -- Generate test descriptions --
        testDescriptions{i,1}= sprintf('TEST %s: Compare %s using %s on variable %s, success defined as p%s%.3f.', ...
            num2str(i), char(defsText{1,3}{i}), defsText{1,1}{i}, char(defsText{1,2}{i}), char(defsText{1,4}{i}), defsText{1,5}(i));
    end
    
end
