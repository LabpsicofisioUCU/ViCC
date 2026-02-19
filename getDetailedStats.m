function detailedStats = getDetailedStats(varsData, finalSelec, tests)
%GETDETAILEDSTATS Compute descriptive and inferential statistics for a selection.
%
%   detailedStats = GETDETAILEDSTATS(varsData, indices, tests) computes per-test
%   statistics (e.g., p-values from ttest2/anova1) and group-wise descriptive
%   summaries for the selected indices in each group.
%
%   Inputs:
%     varsData - Kx2 cell array: {valuesVector, varName}, indexed by image.
%     indices  - 1xG cell array; indices{g} contains selected image indices for group g.
%     tests    - 1xT cell array of test structs with fields: type, var, groups, op, thresh
%
%   Output:
%     detailedStats - Struct array (one element per test) containing:
%                    variable name, test type, compared groups, p-value,
%                    and per-group descriptive statistics.
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

    detailedStats = struct([]);

    for i = 1:length(tests)
        cfg = tests{i};
        
        detailedStats(i).test = cfg;

        % -- Resolve variable row by name --
        varRow = [];
        for r = 1:size(varsData,1)
            if strcmp(varsData{r,2}, cfg.var)
                varRow = r;
                break;
            end
        end
        if isempty(varRow)
            error(['Variable "' cfg.var '" not found in varsData.']);
        end
        values = varsData{varRow,1};  % numeric vector across all images
    
        % -- Collect group values --
        cols = cfg.groups;
        if any(cols > numel(finalSelec))
            error(['Group index out of bounds for variable "' cfg.var '".']);
        end
        groupValues = cell(1, numel(cols));
        for k = 1:numel(cols)
            idx = finalSelec{cols(k)};
            groupValues{k} = values(idx);
        end

        % -- Run supported tests --
        switch cfg.type
            case 'ttest2'
                if numel(groupValues) ~= 2
                    error('ttest2 requires exactly two groups.');
                end
                [h,p,ci,stats] = ttest2(groupValues{1}(:), groupValues{2}(:));
                detailedStats(i).p = p;
                detailedStats(i).stats =stats;
                detailedStats(i).ci = ci;

            case 'anova1'
                x = []; g = [];
                for k = 1:numel(groupValues)
                    x = [x; groupValues{k}(:)];
                    g = [g; k * ones(numel(groupValues{k}),1)];
                end
                [p, anovatab, stats] = anova1(x, g, 'off');
                detailedStats(i).p = p;
                detailedStats(i).stats = stats;
                detailedStats(i).anovatab = anovatab;

            otherwise
                error(['Unsupported test type: ' cfg.type]);
        end

        % -- Apply operator to p-value --
        switch cfg.op
            case '<',  testSuccess = p <  cfg.thresh;
            case '>',  testSuccess = p >  cfg.thresh;
            otherwise, error(['Unsupported operator: ' cfg.op]);
        end
        
    
    end
end