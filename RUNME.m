
% Output directory for calculated data - biotemperature, precipitation,
% life zone classifications
output_dir = './data_calculated/';
data_dir_base = '/users/armen/Data/HLZ_Data/';


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
%% 


writetable(make_unique_code_table(readgeoraster(fullfile(output_dir, ...
    'HLZ_Classical.tif')),hlz_defs.veg_class),fullfile(output_dir,"HLZ_Codes_Classical.csv")); 
