function success = saveSetsToCSV(final_selec, ImagesData, groupNames)
%SAVESETSTOCSV Export selected stimulus sets to per-group CSV files.
%
%   success = SAVESETSTOCSV(final_selec, ImagesData, groupNames) writes one CSV
%   file per group containing the selected images and their associated variables.
%
%   Inputs:
%     final_selec - 1xG cell array; final_selec{g} contains selected image indices.
%     ImagesData  - 1xN struct array; one element per image with fields such as File
%                  and any computed/imported variables.
%     groupNames  - 1xG cell array of group names (used for output filenames).
%
%   Output:
%     success	  - Returns true on success; false otherwise.
%
%   Notes:
%     - Each output file contains the selected filenames and all scalar fields from ImagesData.
%     - Output filenames are derived from groupNames.
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

    success = true;
    try
        for i = 1:size(final_selec,2)

            resultsFilename = [groupNames{i} '_' datestr(now, 'yymmdd_HHMM') '.csv'];

            setData = ImagesData(final_selec{i});
            colTitles = fieldnames(ImagesData);
            
            titlesRow = [sprintf('%s;', colTitles{:}) sprintf('\n')];

            fid = fopen(resultsFilename, 'w');
            fprintf(fid, titlesRow);
	
            for j = 1:size(setData,2) % Rows in set
                singleImageData = struct2cell(setData(j));
                imgDataRow = [sprintf('%s;', singleImageData{1}), sprintf('%f;', singleImageData{2:end}), sprintf('\n')];
                fprintf(fid, imgDataRow);	
            end
            fclose(fid);    
        end
    catch
        success = false;
    end
end
	
