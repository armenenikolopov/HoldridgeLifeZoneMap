% Calculate Biotemperature, Annual Precipitation, and NoData Mask
% requires data_dir_base and output_dir to be set. 
% This script loads WorldClim precipitation and temperature data (in GeoTIFF format) 
% and calculates:
%   1) Annual Biotemperature (actual and sea-level adjusted).
%   2) Annual Precipitation.
%   3) A NoData mask (indicating pixels where data is missing in any monthly file).

% The results are saved as GeoTIFF files in "output_dir".
% The LAPSE_RATE is used to adjust temperature to sea-level as per Holdridge (1967).


%% 1) SETUP
% Directory containing the WorldClim GeoTIFF files
data_dir_worldclim = fullfile(data_dir_base,"WorldClim2.1/")
data_dir_prec  = fullfile(data_dir_worldclim, 'wc2.1_30s_prec');
data_dir_tavg  = fullfile(data_dir_worldclim, 'wc2.1_30s_tavg');
fname_elev    = fullfile(data_dir_worldclim, 'wc2.1_30s_elev.tif');

% Base names for each type of file
prec_fbasename = 'wc2.1_30s_prec_'; 
tavg_fbasename = 'wc2.1_30s_tavg_';


% Dimensions of the WorldClim rasters (30s resolution)
width  = 43200; 
height = 21600; 

% Lapse rate for temperature adjustment (Holdridge 1967: 6°C per 1000 m = 0.006°C/m)
LAPSE_RATE = 0.006;

% Month lengths and total days in a (non-leap) year 
monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
totalDays    = 365;  % used for weighted monthly averages

% Initialize a logical mask to keep track of valid data (where all data are present)
mask = true(height, width);

%% 2) CALCULATE ANNUAL BIOTEMPERATURE
% "Biotemperature" is temperature with negative values set to zero
% (and optionally capped at 30°C by some definitions).

% Load elevation data for sea-level temperature adjustment
[dataElev, georef] = readgeoraster(fname_elev);

% Prepare accumulators for the average biotemperature (actual & sea-level)
annualBiotemp          = zeros(height, width, 'single');
annualSealevelBiotemp  = zeros(height, width, 'single');

% Loop through all 12 months
for k = 1:12
    fprintf("Calculating biotemperature for month %d\n", k);
    
    % Build the monthly TAVG filename, then read data
    fname_tavg = fullfile(data_dir_tavg, sprintf("%s%02d.tif", tavg_fbasename, k));
    [dataTavg, georef] = readgeoraster(fname_tavg);
    info_tavg     = georasterinfo(fname_tavg);

    % Update the NoData mask for this month's TAVG
    mask = mask & ~(dataTavg == info_tavg.MissingDataIndicator);

    % Calculate sea-level adjusted temperature:
    %   T_sealevel = T_actual + (Elevation * LapseRate)
    dataSealevelTemp = single(dataTavg) + single(dataElev) * single(LAPSE_RATE);

    % Clip any negative values to 0 (some definitions also cap at 30°C)
    dataSealevelTemp = max(dataSealevelTemp, 0);
    dataSealevelTemp = min(dataSealevelTemp, 30);

    % Apply biotemperature definition  
    dataBiotemp = max(dataTavg, 0);
    dataBiotemp = min(dataBiotemp, 30);

    % Weight by month length and accumulate (average over 365 days)
    annualBiotemp         = annualBiotemp         + dataBiotemp       * (monthLengths(k) / totalDays);
    annualSealevelBiotemp = annualSealevelBiotemp + dataSealevelTemp  * (monthLengths(k) / totalDays);
end

% Write out the annual biotemperature rasters
geotiffwrite(fullfile(output_dir, "biotemp_annual.tif"),          annualBiotemp,         georef);
geotiffwrite(fullfile(output_dir, "biotemp_sealevel_annual.tif"), annualSealevelBiotemp, georef);

% Clear unneeded variables
clear dataBiotemp dataSealevelTemp annualBiotemp annualSealevelBiotemp dataTavg dataElev;

%% 3) SUM MONTHLY PRECIPITATION & CREATE NODATA MASK
% We simply sum all 12 months of precipitation to get the annual total.

annualPrec = zeros(height, width, 'single');  % accumulator for annual precipitation

for k = 1:12
    fprintf("Calculating precipitation for month %d\n", k);
    
    % Build the monthly PREC filename, then read data
    fname_prec = fullfile(data_dir_prec, sprintf("%s%02d.tif", prec_fbasename, k));
    [dataPrec, georef] = readgeoraster(fname_prec);
    info_prec     = georasterinfo(fname_prec);

    % Update mask wherever precipitation data is missing
    mask = mask & ~(dataPrec == info_prec.MissingDataIndicator);

    % Add this month's precipitation to the annual total
    annualPrec = annualPrec + single(dataPrec);
end

% Write out the annual precipitation raster
geotiffwrite(fullfile(output_dir, "prec_annual.tif"), annualPrec, georef);

% Write out the NoData mask (true = data missing, hence ~mask)
geotiffwrite(fullfile(output_dir, "nodata_mask.tif"), ~mask, georef);

% Clear remaining large variables
clear annualPrec mask dataPrec;
fprintf("All calculations complete.\n");
