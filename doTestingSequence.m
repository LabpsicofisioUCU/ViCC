function [ok, passedTests] = doTestingSequence(varsData, indices, tests, mode)
%DOTESTINGSEQUENCE Evaluate statistical constraints on grouped data.
%
%   [ok, passedTests] = DOTESTINGSEQUENCE(varsData, indices, tests, mode)
%   runs each test in 'tests' on the requested variable, grouped by 'indices'.
%   Each test passes if its p-value satisfies the configured operator and
%   threshold (e.g., p > 0.20 for similarity, p < 0.05 for required differences).
%
%   Inputs:
%     varsData  - Kx2 cell array: {valuesVector, varName}. valuesVector is
%                indexed by image index.
%     indices   - 1xG cell array; indices{g} contains image indices for group g.
%     tests     - 1xT cell array of structs with fields: type, var, groups, op, thresh
%     mode      - 'all' or 'earlyExit'
%
%   Outputs:
%     ok         - true if all tests pass (or until first failure in earlyExit).
%     passedTests- 1xT logical vector of per-test pass/fail.
%
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

    ok = true;
    passedTests = false(1, length(tests));  % logical row vector

    for i = 1:length(tests)
        cfg = tests{i};

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
        if any(cols > numel(indices))
            error(['Group index out of bounds for variable "' cfg.var '".']);
        end
        groupValues = cell(1, numel(cols));
        for k = 1:numel(cols)
            idx = indices{cols(k)};
            groupValues{k} = values(idx);
        end

        % -- Run supported tests --
        switch cfg.type
            case 'ttest2'
                if numel(groupValues) ~= 2
                    error('ttest2 requires exactly two groups.');
                end
                [~, p] = ttest2(groupValues{1}(:), groupValues{2}(:));

            case 'anova1'
                x = []; g = [];
                for k = 1:numel(groupValues)
                    x = [x; groupValues{k}(:)];
                    g = [g; k * ones(numel(groupValues{k}),1)];
                end
                p = anova1(x, g, 'off');

            otherwise
                error(['Unsupported test type: ' cfg.type]);
        end

        % -- Apply operator to p-value --
        switch cfg.op
            case '<',  testSuccess = p <  cfg.thresh;
            case '>',  testSuccess = p >  cfg.thresh;
            otherwise, error(['Unsupported operator: ' cfg.op]);
        end

        passedTests(i) = testSuccess;

        % -- Early exit mode --
        if strcmp(mode, 'earlyExit') && ~testSuccess
            ok = false;
            return;
        end
    
    end
end