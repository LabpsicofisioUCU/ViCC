function baseSetsDefs = generateBaseSetsDefs(ImagesData, filename)
%GENERATEBASESETSDEFS Load group definitions and compute eligible image pools.
%
%   baseSetsDefs = GENERATEBASESETSDEFS(ImagesData, baseSetsFullFile) reads a
%   base-set definition CSV (e.g. basesets.csv) and builds group definitions for
%   ViCC. For each group, the function applies the specified filters to ImagesData
%   and returns the indices of eligible images plus the requested sample size.
%
%   Inputs:
%     ImagesData       - 1xN struct array; one element per image with named fields.
%     baseSetsFullFile - Full path to the base-set definition CSV file.
%
%   Output:
%     baseSetsDefs     - Group definitions including group name, required N, and
%                        eligible image indices after applying filters.
%
%   Notes:
%     - Filter rules are combined with logical AND.
%     - Numeric comparisons use operators such as <, <=, >, >=, =.
%     - Field names in the CSV must match fields present in ImagesData.
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

    % Open file and read all lines
    fid = fopen(filename,'r');
    if fid==-1
        error('Could not open file %s', filename);
    end
    C = textscan(fid,'%s','Delimiter','\n','Headerlines',1);
    fclose(fid);
    lines = C{1};

    % Allowed operators
    opsList = {'<=','>=','<','>','='};

    baseSetsDefs = cell(numel(lines),4);

    for g = 1:numel(lines)
        % Split line by semicolon
        parts = regexp(lines{g}, ';', 'split');

        % First two columns: label and size
        label   = strtrim(parts{1});
        sizeVal = str2double(parts{2});

        defStruct = [];
        % Remaining columns are filters
        for k = 3:length(parts)
            raw = strtrim(parts{k});
            if isempty(raw)
                continue;
            end

            % Find operator manually
            opFound = '';
            for oi = 1:length(opsList)
                if ~isempty(strfind(raw, opsList{oi}))
                    opFound = opsList{oi};
                    break;
                end
            end
            if isempty(opFound)
                disp(['Warning: no operator found in filter "' raw '"']);
                continue;
            end

            % Split into variable and threshold
            tokens = regexp(raw, ['(.+)' opFound '(.+)'], 'tokens');
            if isempty(tokens)
                continue;
            end

            f.var    = strtrim(tokens{1}{1});
            f.op     = opFound;
            f.thresh = str2double(tokens{1}{2});

            defStruct = [defStruct; f];
        end

        % Store in output cell array
        baseSetsDefs{g,1} = label;
        baseSetsDefs{g,2} = sizeVal;
        baseSetsDefs{g,3} = defStruct;
        % Column 4 reserved for indices later
        
    end
    
    % -- Stimulus sets definition parameters -- 
    % Class label, number of elements required, set definitions (as
    % structure).

    % Apply filters according to base set definitions
    for i = 1:size(baseSetsDefs,1)
       
        def = baseSetsDefs{i,3}; % struct with var/op/thresh
        mask = true(1,length(ImagesData)); % initialize logical mask
    
        % Apply each condition
        for j = 1:length({def.var}) % Loop over filters
        
            % Get the complete values set for chosen variable
            x = [ImagesData.(def(j).var)]; 
        
            % Apply filters (using logical AND)
            switch def(j).op
                case '<',  mask = mask & (x <  def(j).thresh);
                case '>',  mask = mask & (x >  def(j).thresh);
                case '<=', mask = mask & (x <= def(j).thresh);
                case '>=', mask = mask & (x >= def(j).thresh);
                case '=', mask = mask & (x == def(j).thresh);
                otherwise, error(['Unknown operator: ' def.op{j}]);
            end
            
        end
    
        % Column 4: eligible indices.
        baseSetsDefs{i,4} = find(mask);
    end
end