function [ivHeaders, ivData] = importVariables(indepVarPath,indepVarFile)
%IMPORTVARIABLES Import per-image variables from a CSV file.
%
%   [ivHeaders, ivData] = IMPORTVARIABLES(indepVarPath, indepVarFile) reads a
%   semicolon-separated CSV containing per-image variables. The first column
%   must contain image filenames; remaining columns must be numeric variables.
%
%   Inputs:
%     indepVarPath - Folder path containing the CSV file.
%     indepVarFile - CSV filename (e.g., 'indepvar.csv').
%
%   Outputs:
%     ivHeaders - 1xM cell array of variable names (excluding the filename column).
%     ivData    - Struct with fields:
%                .files : 1xN cell array of filenames
%                .data  : NxM numeric array of imported values
%
%   Notes:
%     - Column separators are ';'.
%     - Filenames must match the image files used later in the pipeline.
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


    % Get header contents IOT define variable names
    fid = fopen(fullfile(indepVarPath,indepVarFile),'r'); %open file
    headerLine = fgetl(fid);                 
    ivHeaders = regexp(headerLine, ';', 'split');

    % Build format specifications for reading columns
    % First column is string: Filename (name.extension)
    numExtraVars = numel(ivHeaders)-1;
    formatSpec = ['%s' repmat(' %f',1,numExtraVars)]; 

    % Get independent variables data
    ivData = textscan(fid, formatSpec, 'Delimiter',';', 'EndOfLine','\r\n', 'Whitespace',' ');
    fclose(fid); %close file

end