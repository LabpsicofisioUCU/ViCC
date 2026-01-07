function resizeLog = normalizeImgSize(rawImgFolder, resImgFolder, intendedNRowsL, intendedNColsW)
%NORMALIZEIMGSIZE Resize images to a common resolution for ViCC processing.
%
%   NORMALIZEIMGSIZE(rawImgFolder, resImgFolder, intendedNRowsL, intendedNColsW)
%   reads images from rawImgFolder, resizes each image to the specified size,
%   and writes the resized images to resImgFolder.
%
%   Inputs:
%     rawImgFolder     - Folder containing original images.
%     resImgFolder     - Output folder for resized images (created if needed).
%     intendedNRowsL   - Target number of rows (image height in pixels).
%     intendedNColsW   - Target number of columns (image width in pixels).
%
%   Output:
%     None. Resized images are written to disk. A resize log is saved in the
%     output folder for traceability.
%
%   Notes:
%     - Images are resized exactly to the target dimensions (aspect ratio is not preserved). 
%     - Supported formats depend on MATLAB imread/imwrite.
%
% % Copyright (C) 2025 J. A. Friedl & D. Kessel
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

    
    hwait=waitbar(0,'Creating image set with normalized dimensions...');
    
    % Resize cfg
    outputFormat = 'jpg';   % Common format for stimulus sets
    outputQuality = 100;    % Minimizes compression artifacts
    resizeInterpolation = 'bicubic';    % Preserves spatial-frequency content better
    
    % Initialize output structure
    resizeLog = struct( 'fileName', {}, ...
                        'bytes', {}, ...
                        'rawNrowsL', {}, ...
                        'rawNColsW', {}, ...
                        'targetNRowsL', {}, ...
                        'targetNColsw', {}, ...
                        'actionTaken', {} ...
                        );
    
    % Get image file names array
    rawImgFiles = dir(rawImgFolder);
    
    % Get every image, resize if needed
    for i = 1:length(rawImgFiles) % Iterate through files
    
        % Log file info
        %resizeLog(i).sourceFolder = rawImgFolder;
        resizeLog(i).fileName = rawImgFiles(i).name;
        resizeLog(i).bytes = rawImgFiles(i).bytes;
       
        % Skip directories
        if rawImgFiles(i).isdir==1
            resizeLog(i).actionTaken = 'Ignored: Directory.';
            hwait=waitbar(i/length(rawImgFiles),hwait);
            continue
        end
    
        % Try to create matrix with image data
        try
            rgb = imread(fullfile(rawImgFolder,rawImgFiles(i).name)); 
        catch
            %disp(rawImgFiles(i).name)
            resizeLog(i).actionTaken = 'Ignored: Unreadable or not an image.';
            hwait=waitbar(i/length(rawImgFiles),hwait);
            continue
        end
        
        % Record raw and target dimensions
        resizeLog(i).rawNRowsL = size(rgb,1);
        resizeLog(i).rawNColsW = size(rgb,2);
        resizeLog(i).targetNRowsL = intendedNRowsL;
        resizeLog(i).targetNColsW = intendedNColsW;
        
        % Ensure dimensions are correct: If so, copy; else, resize
        if size(rgb, 1) == intendedNRowsL && size(rgb, 2) == intendedNColsW
            copyfile(fullfile(rawImgFolder,rawImgFiles(i).name), resImgFolder)
            resizeLog(i).actionTaken = 'File copied: Dimensions were correct.';
        else
            rgb2 = imresize(rgb, [intendedNRowsL, intendedNColsW], resizeInterpolation);
            imwrite(rgb2, fullfile(resImgFolder, rawImgFiles(i).name), outputFormat, 'Quality', outputQuality);
            resizeLog(i).actionTaken = 'File resized: Original dimensions mismatched.';
        end
        
        hwait=waitbar(i/length(rawImgFiles),hwait);
        
    end
    
    % -- Save resize log as CSV --
    resizeLogFilename = ['resizelog_' datestr(now, 'yymmdd_HHMM') '.csv'];
    fid = fopen(resizeLogFilename, 'w');
    fprintf(fid, 'Image normalization log  \n');
    fprintf(fid, 'Source folder was %s.\n', rawImgFolder);
    fprintf(fid, 'Final images were written into %s.\n', resImgFolder);
    fprintf(fid, 'Resized images were generated in %s format with quality %d using %s interpolation. \n', outputFormat, outputQuality, resizeInterpolation);
    fprintf(fid, 'Details of the operation follow. \n');
    fprintf(fid, '\n');
    fprintf(fid, 'File name;Raw length in pixels;Raw width in pixels;Target length in pixels;Target width in pixels;Action taken\n');
    for i = 1:length(resizeLog)
        fprintf(fid, '%s;%d;%d;%d;%d;%s', ...
            resizeLog(i).fileName, ...
            resizeLog(i).rawNRowsL, ... 
            resizeLog(i).rawNColsW, ...
            resizeLog(i).targetNRowsL, ...
            resizeLog(i).targetNColsW, ...
            resizeLog(i).actionTaken); 
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    close(hwait)
    
    dialogtext= sprintf('Image size normalization successful.\n Images saved in %s.\n Detailed resizing log available in %s.',resImgFolder,resizeLogFilename);
    uiwait(helpdlg(dialogtext,'Size normalization successful'));
end

    