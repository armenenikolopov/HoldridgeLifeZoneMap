%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Holdridge Life Zone Calculation
% Armen Enikolopov, PhD
% aenikolopov@gmail.com
% 2025
% 
% Published as supplement to dataset & article 
% at DOI: https://doi.org/10.6084/m9.figshare.28236242
%
% This script computes a classification of world climate zones based on
% the Holdridge Life Zone (HLZ) system.
% 
% Significant code is in hlz_classify.m 

%Location for WorldClim2.1 & Aridity Index data. 
data_dir_base = '/users/armen/Data/HLZ_Data/';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output directory for calculated data - biotemperature, precipitation,
% life zone classifications
output_dir = './data_calculated/';

if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

%calculate parameters for model. Only needs to be done once, saves to
%output_dir
calc_biotemp_and_precip

%% Read HLZ Definitions
hlz_defs= readtable('./hlz_defs.csv');
[abt,georef] = readgeoraster(fullfile(output_dir,"biotemp_annual.tif"));
abt_sealevel = readgeoraster(fullfile(output_dir,"biotemp_sealevel_annual.tif"));
prec = readgeoraster(fullfile(output_dir,"prec_annual.tif"));
mask_nodata = readgeoraster(fullfile(output_dir,"nodata_mask.tif"),"OutputType","logical");
elev = readgeoraster(fullfile(data_dir_base,"WorldClim2.1","wc2.1_30s_elev.tif"));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%calculate holdridge life zones using Holdridge's evapotranspiration estim.
pet = abt * 58.93; % Use classic Holdridge estimate: PET (mm) = 58.93 * biotemperature
do_calculate_ecotones = true;    %calculate transitional zones for classical HLZ.
fname = fullfile(output_dir, 'HLZ_Classical.tif');
disp("Calculating classical Holdridge life zones")
hlz_classify    %run classifier code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clearvars -except hlz_defs abt abt_sealevel prec mask_nodata georef output_dir data_dir_base elev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%calculate HLZ using Penman-Monteith - unique to PM methods.
pet = single(readgeoraster(fullfile(data_dir_base,"et0_v3_yr.tif")));  %data from Global Aridity Index
do_calculate_ecotones = false;    %don't calculate transitional zones for Penman-Monteith HLZ
fname = fullfile(output_dir, 'HLZ_Penman-Monteith.tif');
disp("Calculating Penman-Monteith-adjusted Holdridge life zones. ")
hlz_classify   %run classifier code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% The geoTIFFs are made now. Note, need to specify no data value =0
%%% manually, I do this with gdal.

%%Make CSV that contains names for all used zones.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars -except hlz_defs output_dir

writetable(make_unique_code_table(readgeoraster(fullfile(output_dir, ...
    'HLZ_Classical.tif')),hlz_defs.veg_class),fullfile(output_dir,"HLZ_Codes_Classical.csv")); 
writetable(make_unique_code_table(readgeoraster(fullfile(output_dir, ...
    'HLZ_Penman-Monteith.tif')),hlz_defs.veg_class),fullfile(output_dir,"HLZ_Codes_Penman-Monteith.csv")); 
