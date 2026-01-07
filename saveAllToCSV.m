function success = saveAllToCSV(ImagesData)
%SAVEALLTOCSV Export ImagesData structure to a CSV file.
%
%   csvFile = SAVEALLTOCSV(ImagesData) writes a CSV file containing one row per
%   image and one column per field in ImagesData. The first column contains the
%   image filename (ImagesData.File).
%
%   Input:
%     ImagesData - 1xN struct array; one element per image with scalar numeric
%                 fields and a filename field.
%
%   Output:
%     csvFile    - Full path to the written CSV file.
%
%   Notes:
%     - Column order follows the field order in ImagesData.
%     - Non-scalar or non-numeric fields are not supported (unless explicitly handled).
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
        
        allDataFilename = ['ImagesData_' datestr(now, 'yymmdd_HHMM') '.csv'];

        setData = ImagesData;
        colTitles = fieldnames(ImagesData);
        titlesRow = [sprintf('%s;', colTitles{:}) sprintf('\n')];

        fid = fopen(allDataFilename, 'w');
        fprintf(fid, titlesRow);
	
        for j = 1:size(setData,2) % Rows in this set.
            singleImageData = struct2cell(setData(j));
            imgDataRow = [sprintf('%s;', ImagesData(j).File), sprintf('%f;', singleImageData{2:end}), sprintf('\n')];
            fprintf(fid, imgDataRow);	
        end
            fclose(fid); 
        
        uiwait(msgbox(sprintf('You also have an image values dataset, which was exported as %s.\n\nThis is a copy of the ImagesData structure but readable by humans. You can use it for statistical analyses or data transparency.',allDataFilename),'Export successful','modal'));
        
    catch
        success = false;
        uiwait(errordlg('Could not export images dataset to CSV.','Error')); 
    end
   
end
	
