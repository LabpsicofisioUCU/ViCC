% ViCC (Visual Confounder Control) - interactive entry script.
%
% Run this script to guide the user through the ViCC pipeline for building
% stimulus sets (experimental conditions) under statistical constraints.
%
% The workflow includes optional image size normalization, import of external
% variables from CSV files, computation of physical image descriptors
% (luminance, contrast and spatial-frequency levels), definition of groups and tests,
% feasibility estimation, and generation of final stimulus sets.
%
% Inputs are selected interactively via dialogs (image folders and CSV files).
% Outputs are written to disk (MAT files, CSV summaries, and diagnostic plots).
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

clear
clc

% -- Color to luminance coefficients (R,G,B)----------
% 709 is used because it is the conversion to luminance values
% corresponding to LCD screens, the standard contemporary hardware for
% digital visual stimulus presentation. The user may change if other
% coefficients are desired.
RGB2LUM= [0.2125, 0.7154, 0.0721];  %709 

% -- Welcome --
uiwait(msgbox(sprintf(['Welcome to ViCC (Friedl & Kessel, 2025)\n\n'...
    'A script for neuroscience research that selects visual stimuli according to your requirements.\n\n'...
    'This user interface will guide you through the procedure.\n\nFor additional information, please refer to Hoyos et al. (in preparation).\n\n',...
    'The first step will be selecting the folder containing the ViCC functions.\n\nPress OK to continue.']),...
    'Welcome to ViCC!','modal'));

% Locate functions
functions_folder = uigetdir('',sprintf('Select the folder containing the ViCC functions.'));
cd(functions_folder)

% -------------------------------------------------
% --- Normalize image dimensions (no overwrite) ---
% -------------------------------------------------
hasNormalizedSet = questdlg( ...
    'Are the images of your set already normalized to the same dimensions (all same width and height)?', ...
    'Size normalization', ...
    'Yes they are!','Not yet / Not sure','Not yet / Not sure');

if strcmp(hasNormalizedSet,'Not yet / Not sure')
   
    uiwait(msgbox(sprintf(['OK. Let us find the images so we can normalize their size.\n\n'...
    'Please choose the folder containing your original image set...']),'Image normalization'));
    
    % Folder with original raw images set
    rawImgFolder = uigetdir(functions_folder,sprintf('Please choose the folder containing your original image set.'));

    % Intended image dimensions
    intendedDimAnswer = inputdlg(...
        {'Enter intended image height in pixels:', ...
        'Enter intended image width in pixels:'}, ...
        'Choose intended image dimensions', ...
        1, ...
        {'768','1024'});
    intendedNRowsL = str2num(intendedDimAnswer{1}); %intended height
    intendedNColsW = str2num(intendedDimAnswer{2}); %intended width
    clear intendedDimAnswer

    % Folder where resized images will be written into
    uiwait(msgbox(sprintf(['Now we need an EMPTY folder to write all the images at the correct size.']),'Image normalization'));
    resImgFolder = uigetdir(functions_folder, sprintf('Select an EMPTY folder for saving the resized images.\nIf you do not have such folder yet, please create it now.'));
    
    % Resize images if needed, write normalization log.
    resizeLog = normalizeImgSize(rawImgFolder, resImgFolder, intendedNRowsL, intendedNColsW);
else
    uiwait(msgbox(sprintf('Great news! We now need to know where these normalized images are. \n\nPlease select the folder where we can find them...'), 'Let''s go get ''em','modal'));
    
    resImgFolder = uigetdir('', 'Select the folder where normalized images are.');
end

% -------------------------------------
% --- Generate (or load) image data ---
%--------------------------------------
hasImagesData = questdlg(sprintf(['Good, we have located the image folder.\n\n'...
    'Do you have a previous ImagesData file, where the computed data for these images is already stored?']), ...
    'Load data structure', ...
    'Yes I do!','Not yet / Not sure', 'Not yet / Not sure');

if strcmp(hasImagesData,'Not yet / Not sure')
    uiwait(msgbox('OK! Let us create an ImagesData structure for them.', 'No problem!','modal'));
    
    uiwait(helpdlg(sprintf(['Let''s set up our analysis.\n\n'...
        'The first thing we will compute is the luminance of each image.\n'...
        'Conversion coefficients will be %.4f for red, %.4f for green, and %.4f for blue.\n\n'...
        'Next, we will compute the image contrast. We use the population standard deviation of pixel intensity for that.\n\n'...
        'And then, we will do a spatial frequency analysis of each image. '...
        'Default parameters are generally OK but you may change them in the next dialog box if you need to.'],...
        RGB2LUM(1), RGB2LUM(2), RGB2LUM(3)),...
        'Physical variables'));

    % -- Analyze images and import into a structure --
    
    % Spatial frequency analysis parameters dialog box,
    % Adapted from freqspat_gui() by N'Diaye & Delplanque (2007)
    % under the terms of GNU General Public License v3
    % as published by the Free Software Foundation.
    wavparams = inputdlg(...
        {'Spatial frequency analysis wavelet transform name:', ... 
        'Number of levels used:'}, ...
        'Configure spatial frequency analysis', ...
        1, ...
        {'haar','8'});
    %-

    uiwait(helpdlg(sprintf(['In addition to the physical variables, there may also be other variables you want to consider when selecting your stimulus sets (e.g. picture type, emotional variables).\n\n\n'...
        'We will import the data for these variables from a CSV file that has to be in a specific format, as follows:\n\n'...
        '1) A first column titled File_Name with the stimulus image filenames with extensions (e.g. image1.jpg), one image per row.\n\n'...
        '2) Additional columns to the right should each contain as header the name of the variable you want to include (one per column, avoid spaces), and below, the numeric values of that variable corresponding to each image.\n\n'...
        '3) Ensure you are using semicolon (;) as field separator, and dot (.) as decimal separator.\n\n\n'...
        'To make this easier, we provide a template file called indepvar.csv containing fictional data, which you can adapt to the real stuff.\n\n'...
        'You can save it with any name you like - as long as it is in the right format we''ll be able to read it. (If you don''t use additional variables, an empty CSV will do).\n\n'...
        'Press OK when your CSV is ready to go.\n\n']),...
        'Additional variables'));
 
    % -- Import additional variables --
    [indepVarFile, indepVarPath] = uigetfile(... 
        '*.csv', ...
        'Import variables file', ...
        'indepvar.csv'); 
    % Field delimiter is ";", decimal separator is "."
    % First column contains the filename.
    % The following columns contain variables and their values.
    % Filenames in filenames column should not be enclosed in ' ' or anything,
    % just the filename e. g. picture1.jpg
    
    [ivHeaders, ivData] = importVariables(indepVarPath,indepVarFile);
    
    uiwait(msgbox(sprintf(['Good. Now let''s process all those images to make the data structure.\n\n'...
        'This may take a short while.\n\n'...
        'Press OK to start.']),'All systems ready','modal'))
    
    % -- Sequentially read and process img data --
    % processImages function uses freqspat.m function by N'Diaye & Delplanque (2007). 
    % Article DOI: https://doi.org/10.1016/j.jneumeth.2007.05.030
    
    ImagesData = processImages(resImgFolder,ivHeaders,ivData,RGB2LUM,wavparams);

    % -- Save MatLab file containing the structure with the image data --
    imagesDataFilename = ['ImagesData_' datestr(now,'yyyymmdd_HHMM') '.mat'];
    save(imagesDataFilename, 'ImagesData','ivHeaders','ivData')
    structureFieldNames=fields(ImagesData);
    structureFieldNamesStr= sprintf('%s, ', structureFieldNames{:});
    uiwait(helpdlg(sprintf(['OK. Now we have a data structure corresponding to %0.f images.\n\n' ...
        'It contains the following information about the images: '...
        '%s'],size(ImagesData,2),structureFieldNamesStr),...
        'Good!'));
    uiwait(helpdlg(sprintf('Current ImagesData structure saved as %s.\n\nYou can retrieve this in the future if you need to.',imagesDataFilename), 'Results saved'));
    
    % -- Export CSV --
    saveAllToCSV(ImagesData); 
else
    uiwait(msgbox('OK! Let us get that ImagesData structure file.', 'Good!','modal'));
    uiopen('LOAD');
    structureFieldNames=fields(ImagesData);
    structureFieldNamesStr= sprintf('%s, ', structureFieldNames{:});
    uiwait(helpdlg(sprintf(['OK. Now we have a data structure corresponding to %0.f images.\n\n' ...
        'It contains the following information about the images: '...
        '%s'],size(ImagesData,2),structureFieldNamesStr),...
        'Good!'));
end


% ---------------------------------------------
% --- Generate base stimulus condition sets ---
% ---------------------------------------------
uiwait(helpdlg(sprintf(['Our next step is to define the base sets from which to draw the number of images your experiment requires.\n\n'...
    'For this we will use another CSV file, in a specific format. \n\n\n'...
    'This definition file should contain at least three columns:\n\n'...
    '1) The first column titled Group_Label should contain in the rows below a textual identifier for each stimulus group you want.\n'...
    'Example: Neg for negative images.\n'...
    '(Doesn''t have to be telegraphic, just avoid using spaces in the group labels or elsewhere).\n\n'...
    '2) A second column titled Required_N should contain the number of images your experiment requires of each category.\n'...
    'Example: 50 if you need 50 negative images.\n\n'...
    '3) The third and subsequent columns titled Filter_... should contain the inclusion criteria that define each base set.\n\nFor each base set, you may define as many filters as you want, using successive columns to the right.\n\n\n'...
    'Each filter is written as a concatenation of a variable name, a mathematical operator, and a threshold value. Supported operators are <=, >=, <, >, and =.\n'...
    'Example: Valence<0.5\n\n'...
    'Filters are applied conjunctively.\n\n'...
    'You can define a range of values for one variable by applying two different filters.\n'...
    'Example: To include images with Valence between 4 and 6, define Filter_1 as Valence>4, and Filter_2 as Valence<6.\n\n'...
    'Ensure the file uses semicolon (;) as field separator and dot (.) as decimal separator.\n'...
    '\n\n' ...
    'To make all this much easier for you, we provide a template file called basesets.csv, which you can adapt to your own set definitions.\n\n'...
    'When your set definitions file is ready, press OK, and we''ll load it!']),...
    'Defining stimulus sets'));

% -- Import base sets definitions --
% This not only loads but also generates the fourth column containing the
% indices of the set elements. 
% 'basesets.csv' is provided as template.
% User can choose different filenames for different base set configurations
% Files with different names will work as long as they are in the required format

[baseSetsDefsFile, baseSetsDefsPath] = uigetfile(...
    '*.csv',...
    'Select base sets definitions file',...
    'basesets.csv'); 
baseSetsFullFile= fullfile(baseSetsDefsPath,baseSetsDefsFile);

baseSetsDefs = generateBaseSetsDefs(ImagesData, baseSetsFullFile);

baseSetsNCandidates={};
for i = 1:size(baseSetsDefs,1)
    baseSetsNCandidates{i,1}= size(baseSetsDefs{i,4},2);
end

setDiagnosisString=sprintf(['OK. We have filtered the images data according to your base sets definitions.\n\n'...
    'In the table below you can see the results. '...
    'The second column shows how many images you ask for, the last column shows how many candidate images fit the criteria you specified.\n\n'...
    '%-20s%-20s%-20s\n'],'GROUP LABEL','REQUIRED N','AVAILABLE N');
for i=1:numel(baseSetsDefs(:,1))
    %Write set names, candidates count, and number required by user
    diagnRow=sprintf('%-20s%-20.0f%-20.0f\n',baseSetsDefs{i,1},baseSetsDefs{i,2},baseSetsNCandidates{i,1});
    setDiagnosisString=[setDiagnosisString diagnRow];
end
setDiagnosisString=[setDiagnosisString, sprintf('\n\nIf the numbers don''t look good, you may edit your set definitions CSV file and restart the program to try the new parameters.')];

% Show the user what the specified filters allow.
uiwait(helpdlg(setDiagnosisString,'Image set sizes'));


% ------------------------------------
% --- Specify tests and parameters ---
% ------------------------------------
uiwait(helpdlg(sprintf(['We are almost there! \n\n'...
    'The final thing we need to know is the statistical tests the sets will need to "pass" to get the desired level of confounder control.\n\n'...
    'As you may have noticed, this script likes CSV files very much, so we will feed it a test definition CSV file.\n\n'...
    'The test definition file should contain five columns: Test_Type, Variable, Groups, Operator, and Threshold. '...
    'Each subsequent row below the header row defines a single test. You may configure as many tests as you need!\n\n\n'...
    'TEST_TYPE specifies the statistical test to be applied. Currently supported are ttest2 (two-sample t-test) and anova1 (one-way ANOVA).\n'...
    'Example: ttest2\n\n'...
    'VARIABLE indicates the variable the test will be applied to.\nExample: Luminance.\n\n'...
    'GROUPS lists the labels for the groups to be included in the test, separated by commas (no spacing).\nExample: Neg,Pos,Neu\n\n'...
    'OPERATOR and P_THRESHOLD define the acceptance criterion for the resulting p-value. Example: < in OP column and 0.05 in THRESH column indicate that the test is passed if p<0.05.\n\n\n'...
    'Of course, all this is much easier with a template, so we provide one (testdefs.csv).\n\n'...
    'Feel free to customize and save versions with different names - as long as the format is correct, the script won''t complain.\n\n'...
    'Press OK when your test definitions are ready.'
    ]),...
    'Defining statistical tests'));

% Test definitions are formed as structures which then are fed to the 
% evaluator function, whose arguments take the form 'variable', 'value'.
groupNames = baseSetsDefs(:,1)'; % Get names from set definitions data

% -- Import test definitions --
% Field separator is ";", values separator is ",", decimal separator is "."
[testDefFile, testDefPath] = uigetfile(...
    '*.csv',...
    'Select test definitions file',...
    'testdefs.csv');
[tests, testDescriptions] = loadTestDefs(groupNames,testDefPath,testDefFile);

% -- Do exploratory run and generate optimized test sequence --
uiwait(msgbox('OK. Let us explore the dataset with the tests you just loaded.'));

% Set recon parameter
nReconTrialsUI = inputdlg(...
    {'Enter the number of exploratory trials to be performed on the image set. The program will perform that number of random draws from the set, applying all tests you specified, and return the frequency of success for each test.'}, ...
    'Exploration settings', ...
    1, ...
    {'10000'});
nReconTrials = str2num(nReconTrialsUI{1,1});

% Call recon function to apply all specified tests to a sample of draws
passEvents = reconnoiter(nReconTrials, ImagesData, baseSetsDefs, tests);

% Compute joint probability from observed frequencies
passRelFreq = passEvents/nReconTrials;
joint_prob=prod(passRelFreq);

%If any test showed zero pass events, use Laplace smoothing
usedLaplace=false;
if joint_prob==0
    joint_prob = prod((passEvents+1)/(nReconTrials+1));
    usedLaplace =true;
end

% Estimate median number of trials that will be required.
% Formula assumes geometric distribution from independent Bernoulli trials.
singleDrawsExpected = ceil(log(0.5)/log(1-joint_prob));

if usedLaplace == true
    uiwait(warndlg(sprintf('One or more tests returned zero success events after %d attempts.\nLaplace smoothing was used to enable joint probability estimation. The estimate may therefore be very conservative.',nReconTrials)));
end

% -- Plot estimated probabilities --
figpos=get(0,'DefaultFigurePosition');% coordinates: x, y, widhth, height
deffontsize=get(0,'DefaultTextFontSize'); %
newheight =figpos(4)+length(testDescriptions)*deffontsize*2;

figure('Position', [figpos(1), figpos(2)-newheight+figpos(4), figpos(3)+100, newheight])
bar(passRelFreq);
set(gcf,'Name','Exploration results report');
set(gcf,'Units','normalized','OuterPosition',[0 0 1 1]);
ylim([0,1])
set(gca, 'XTick',1:numel(passRelFreq));
xlim([0,numel(passRelFreq)+0.5])
title(sprintf('Individual criteria pass estimated probabilities\n(%d exploration trials done, estimated trials for fit around %.0f)',nReconTrials,singleDrawsExpected));
ylabel('Probability')
set(gca, 'Position', [0.1 0.4 0.8 0.5])
text(0,-0.45, sprintf('%s\n', testDescriptions{:}),'FontSize',10)
%set(gcf,'CloseRequestFcn',@uiresume);
graphFileName=['ExplorationReport_' datestr(now, 'yymmdd_HHMM') '.png'];
saveas(gcf,graphFileName);
%uiwait(gcf);

% -- Reorder test sequence dynamically --
% Test indices are reordered by ascending relative observed pass event freq
% "Harder" tests are scheduled first to ensure earliest possible loop exit
% Test_order is an array of indices.
[~, test_order] = sort(passRelFreq);



wantsToGenerate = questdlg(...
    sprintf(['Estimated trials for fit are around %.0f.\n\n'...
    '(If there are more than seven figures this means it will take a while)\n\n'...
    'We will now generate the sets you specified.\n\n'...
    'This uses parallel processing so don''t be scared if your computer makes airplane sounds while generating the sets, it''s completely normal.\n\n'...
    'Press START when you are ready to close the graph and begin generating the sets (graph is automatically saved).\n\n'...
    'If you do not want to generate the sets now, press CANCEL.'],singleDrawsExpected),...
    'Ready for set generation','START','CANCEL','START');

close all

% ---------------------------------------------------------
% --- Generate sets consistent with user specifications ---
% ---------------------------------------------------------

if strcmp(wantsToGenerate,'START')
    
    % -- Generate sets --
    [final_selec, detailedStats] = generateSets(ImagesData, baseSetsDefs, tests, test_order, singleDrawsExpected);

    customIconData=1:64;customIconData=(customIconData'*customIconData)/64;
    uiwait(msgbox(sprintf('Your sets are ready!\n\nNow it''s time to save the results.\n\nClick on the detailedStats structure in your workspace to see statistics for each test.\n\nDouble-click on any cell to see the details! (e.g. on any 1x1 struct, each one represents a test)'),'Congrats!','custom',customIconData,hot(64)))
    % -- Save set and stats --
    uisave('final_selec', ['Selection_' datestr(now,'yyyymmdd_HHMM') '.mat'])
    uisave('detailedStats', ['Selection_stats_' datestr(now,'yyyymmdd_HHMM') '.mat'])

    success = saveSetsToCSV(final_selec, ImagesData, groupNames);
    
end