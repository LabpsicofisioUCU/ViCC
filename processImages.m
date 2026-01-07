function ImagesData = processImages(resImgFolder,ivHeaders,ivData,RGB2LUM,wavparams)
%PROCESSIMAGES Build ImagesData by computing image descriptors and merging CSV variables.
%
%   ImagesData = PROCESSIMAGES(resImgFolder, ivHeaders, ivData, RGB2LUM, wavparams)
%   reads images from resImgFolder, computes physical descriptors (luminance, contrast, and
%   spatial-frequency band energies), and merges additional per-image variables
%   provided in ivData (imported from indepvar.csv).
%
%   Inputs:
%     resImgFolder - Folder containing images (of normalized size).
%     ivHeaders    - 1xM cell array of variable names imported from CSV.
%     ivData       - Imported variable data aligned to filenames (see importVariables).
%     RGB2LUM      - 1x3 coefficients for RGB-to-luminance conversion.
%     wavparams    - Spatial-frequency analysis parameters (e.g., wavelet type, nBands).
%
%   Output:
%     ImagesData   - 1xN struct array; one element per image with fields:
%                   .File, imported variables, .Luminance, .Contrast, and SF band descriptors.
%
%   Notes:
%     - Luminance is computed from RGB using RGB2LUM coefficients.
%     - Contrast is computed as population standard deviation of luminance.
%     - Spatial-frequency features are computed using freqspat.m (wavelet-based) (N'Diaye & Delplanque, 2007).
%     - Filenames in ivData must match image files (case-sensitive).
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


    hwait=waitbar(0,'Computing image physical parameters...');

    ImagesData = []; % Image attribute data will be stored here

    % List filenames of resized images (exclude directories)
    resImgFiles = dir(resImgFolder); 
    resList = {resImgFiles(~[resImgFiles.isdir]).name};

    for i = 1:length(resList) % For each element in the list
    
        % Load image
        data = imread(fullfile(resImgFolder,char(resList(i))));	
    
        % Record image filename
        ImagesData(i).File=char(resList(i));
    
        % Retrieve and store independent variable values per image.
        indepVarRow=find(strcmp(resList{i}, ivData{1}(:))); % Find corresponding IV data
        for k = 2:numel(ivHeaders)   % start at 2nd column (after filename)
            fieldName = ivHeaders{k};                     % e.g. 'Valence'
            fieldValue = ivData{k}(indepVarRow,1);
            ImagesData(i).(fieldName) = fieldValue;     % dynamic assignment
        end
    
        % Convert to grayscale.
        dataGrey =  RGB2LUM(1)*data(:,:,1) + ...
                    RGB2LUM(2)*data(:,:,2) + ...
                    RGB2LUM(3)*data(:,:,3);
    
        % Compute and store mean luminance (mean pixel value).
        ImagesData(i).Luminance = mean(dataGrey(:));
        
        % Compute and store contrast value.
        ImagesData(i).Contrast = std(double(dataGrey(:)),1); % 2nd arg: RMS
        
        % Compute spatial frequency energy values using FREQSPAT.M,
	% a function by N'DIAYE & DELPLANQUE (2007).
        % Mean values are included; for additional data about freqspat.m
        % see the function documentation.
        [cs_me]=freqspat(dataGrey,str2num(wavparams{2}),wavparams{1});
    
        % Record spatial frequency values dynamically
        for k = 1:(numel(cs_me)-1)
    	    ImagesData(i).(['SF' num2str(k)]) = cs_me(k);
        end
        ImagesData(i).SFResiduals = cs_me(end);
        
        hwait=waitbar(i/length(resList),hwait); % Update waitbar.
    end
    close(hwait) % Close waitbar.
    
end