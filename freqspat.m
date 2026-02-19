% freqspat() - mean and stddev of coefficients from an image's wavelet transform
%
%  Usage:
%    >> [cs_me,c_sd] = freqspat(X,nlevels,wavname);
%    >> [cs_me,c_sd,a,h,v,d] = freqspat(X,nlevels,wavname);
%
%  Inputs:
%       X       : 2D matrix of pixels intensity
%       nlevels : Number of levels in wavelet decomposition.
%                 If unspecified or set to [], use the maximum number based
%                 on image size and wavelet properties.
%       wavname : Name of the wavelet transfor. Default: 'haar'. See
%                 help on WFILTERS
%
%   Outputs:
%       cs_me : mean of the sum of squared coeeficients at each level
%       cs_sd : standard deviation of the sum of squared coeeficients at each level
%           a : cell array of residuals at each level
%           h : cell array of wavelet horizontal coefficient at each level
%           v : cell array of wavelet vertical coefficient at each level
%           d : cell array of wavelet diagonal coefficient at each level
%
%   See also: freqspat_gui()

% Author: K. N'Diaye (kndiaye01<at>yahoo.fr) & S. Delplanque
% Copyright (C) 2007 
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by  the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version: http://www.gnu.org/copyleft/gpl.html
%
% ----------------------------- Script History ---------------------------------
% KND  2007-07-13 Creation
%                   
% ----------------------------- Script History ---------------------------------

function [cs_me,cs_sd,ca,ch,cv,cd]=freqspat(X,nlevels,wavname)
X=double(X);
if nargin<3 | isempty(wavname)
    wavname='haar';
end
if nargin<2 | isempty(nlevels)  
    nlevels=wmaxlev(size(X), wavname);
end
% Compute the 2D Wavelet Transform
[c,s] = wavedec2(X,nlevels,wavname);
for i=1:nlevels
    % Extract coefficients at each level    
    % Horizontal Vertical Diagonal
    [ch{i},cv{i},cd{i}] = detcoef2('all',c,s,i);
    % Sum of squares:
    cs{i}=ch{i}.^2+cv{i}.^2+cd{i}.^2;
    % Compute mean and std dev for each coefficient
    cs_me(i)=mean(cs{i}(:));
    cs_sd(i)=std(cs{i}(:));
    % And approximation coefficients 
    ca{i} = appcoef2(c,s,wavname,i);
end
% residuals (ie. approximation coefficients at the last level)
cs_me(nlevels+1)=mean(ca{end}(:).^2);
cs_sd(nlevels+1)=std(ca{end}(:).^2);
