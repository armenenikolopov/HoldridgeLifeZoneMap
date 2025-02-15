%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Holdridge Life Zone Calculation
% Armen Enikolopov, PhD
% aenikolopov@gmail.com
% 
% Published as supplement to dataset & article 
% at DOI: https://doi.org/10.6084/m9.figshare.28236242
%
% This script computes a classification of world climate zones based on
% the Holdridge Life Zone (HLZ) system, with optional use of the 
% Penman–Monteith model for PET instead of the classic Holdridge formula.
%
% Data Requirements:
%       abt           : annual biotemperature (°C)
%       abt_sealevel  : annual biotemperature at sea level (°C)
%       prec          : total annual precipitation (mm)
%       mask_nodata : logical mask indicating valid data (0=valid, 1=nodata)
%       georef        : georefereing data for file saving
%       
%       elev          : elevation data, in meters. 
%       hlz_defs       : able with HLZ definitions (columns: abt, tap, per, veg_class)
%
% Output:
%   - GeoTIFFs in ./data_calculated:
%       total_hlz_eco_Holdridge.tif   : HLZ classification including
%       ecotones if do_calculate_ecotones is true.
%
% The HLZ code is encoded in base-10 as follows
%       [ 2 digits for veg_class_i | 1 digit for altitude_band | 1 digit for latitudinal_band | 1 digit for ecotone ]
%
% Example: a code like 19263 means:
%       - veg_class_i = 19
%       - altitude_band = 2
%       - latitudinal_band = 6
%       - ecotone = 3
%
% Areas outside model bounds are set to out_of_bounds_code.
% Areas without data in any input layer are set to no_data_code.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Define Constants
min_prec = 62.5;                   % Minimum annual precipitation (mm)
max_prec = 16000;                  % Maximum annual precipitation (mm)

min_abt = 1.5;                     % Lower bound for biotemperature = polar/nivial desert
max_abt = 30;                      % Upper bound for biotemperature

min_petrat = 0.125;                % Minimum PET–precip ratio
max_petrat = 32;                   % Maximum PET–precip ratio

no_data_code = 0;                  % Value for areas with no input data
out_of_bounds_code = 1;            % Value for areas outside HLZ parameters
polar_desert_vegclass = 3;         % Veg class (not code) index for polar/nivial desert


% Indices in hlz_defs for specific zones, allows us to have warm tropical
% and subtropical zones, one hexagon split in half. 
frost_line = 2^(log2(12) + 0.5);        % midpoint of 12 and 24 in log space, splits subtropical and warm temperate
subtropical_index_offset = uint16(15);  % offset to convert warm temperate -> subtropical
warm_temp_desert_index = 20;           % index for warm temperate desert
warm_temp_rain_forest_index = 26;      % index for warm temperate rain forest
tropical_rain_forest_index = 34;       % last zone we consider for distance calc

%% Compute PET–Precipitation Ratio
petrat = pet ./ prec;
clear pet;  % No longer needed, delete to save memory. 

zone_edges = single([hlz_defs.abt, hlz_defs.tap, hlz_defs.per]);

% For Euclidean distance in log space, zone "centers" are taken halfway in 
% log space from zone_edges. 
zone_centers = 2.^(log2(zone_edges) + 0.5);

% Only use the first N=34 zones for distance calculations (through tropical rain forest)
zone_edges = zone_edges(1:tropical_rain_forest_index, :);
zone_centers = zone_centers(1:tropical_rain_forest_index, :);

%% Calculate Nearest HLZ Zones in Log Space Iteratively
% We do this in four chunks to avoid memory overload for large rasters.

% Initialize the result array (HLZ index) 
closest_zone_index = zeros(21600, 43200, 'uint16');

log_zone_centers = [ ...
    log2(zone_centers(:,1)/0.75), ...
    log2(zone_centers(:,2)/62.5), ...
    log2(zone_centers(:,3)/0.125) ...
];

% We use 1-based indexing in MATLAB, so define row/col chunks:
row_len = size(abt,1); 
col_len = size(abt,2); 

% Process chunk 1 (rows 1:10800, cols 1:21600)
tic;
rows = 1:(row_len/2);
cols = 1:(col_len/2);
closest_zone_index(rows, cols) = calculate_closest_points_iterative( ...
    log2(abt(rows, cols)/0.75), ...
    log2(prec(rows, cols)/62.5), ...
    log2(petrat(rows, cols)/0.125), ...
    log_zone_centers ...
);
toc;

% Process chunk 2 (rows 1:10800, cols 21601:43200)
tic;
rows = 1:(row_len/2);
cols = (col_len/2 +1):col_len; 
closest_zone_index(rows, cols) = calculate_closest_points_iterative( ...
    log2(abt(rows, cols)/0.75), ...
    log2(prec(rows, cols)/62.5), ...
    log2(petrat(rows, cols)/0.125), ...
    log_zone_centers ...
);
toc;

% Process chunk 3 (rows 10801:21600, cols 1:21600)
tic;
rows = (row_len/2 +1):row_len; 
cols = 1:(col_len/2);
closest_zone_index(rows, cols) = calculate_closest_points_iterative( ...
    log2(abt(rows, cols)/0.75), ...
    log2(prec(rows, cols)/62.5), ...
    log2(petrat(rows, cols)/0.125), ...
    log_zone_centers ...
);
toc;

% Process chunk 4 (rows 10801:21600, cols 21601:43200)
tic;
rows = (row_len/2 +1):row_len; 
cols = (col_len/2 +1):col_len;
closest_zone_index(rows, cols) = calculate_closest_points_iterative( ...
    log2(abt(rows, cols)/0.75), ...
    log2(prec(rows, cols)/62.5), ...
    log2(petrat(rows, cols)/0.125), ...
    log_zone_centers ...
);
toc;

%% Determine Subtropical vs. Warm Temperate
% If zone index is between warm_temp_desert_index and warm_temp_rain_forest_index
% and the local temperature is above the frost_line, offset the zone index
% by subtropical_index_offset.
veg_class_i = closest_zone_index ...
    + uint16(closest_zone_index >= warm_temp_desert_index ...
             & closest_zone_index <= warm_temp_rain_forest_index ...
             & abt > frost_line) * subtropical_index_offset;

%% Determine Latitudinal Bands (No Elevation Correction)
% 1 = polar, 2 = subpolar, 3 = boreal, 4 = cool temp, 5 = warm temp,
% 6 = subtropical, 7 = tropical
lat_band_local = zeros(size(abt), 'uint16');
lat_band_local(abt <= 1.5)                    = 1; % polar
lat_band_local(abt >= 1.5 & abt < 3)          = 2; % subpolar
lat_band_local(abt >= 3   & abt < 6)          = 3; % boreal
lat_band_local(abt >= 6   & abt < 12)         = 4; % cool temperate
lat_band_local(abt >= 12  & abt < frost_line) = 5; % warm temperate
lat_band_local(abt >= frost_line & abt < 24)  = 6; % subtropical
lat_band_local(abt >= 24)                     = 7; % tropical

%% Determine "Local Altitudinal" Band (Initially same as lat_band_local)
alt_band_local = lat_band_local;

%% Determine Sea-Level Latitudinal Bands
lat_band_sealevel = zeros(size(abt_sealevel), 'uint16');
lat_band_sealevel(abt_sealevel <= 1.5)                              = 1; 
lat_band_sealevel(abt_sealevel >= 1.5 & abt_sealevel < 3)           = 2; 
lat_band_sealevel(abt_sealevel >= 3   & abt_sealevel < 6)           = 3; 
lat_band_sealevel(abt_sealevel >= 6   & abt_sealevel < 12)          = 4; 
lat_band_sealevel(abt_sealevel >= 12  & abt_sealevel < frost_line)  = 5; 
lat_band_sealevel(abt_sealevel >= frost_line & abt_sealevel < 24)   = 6; 
lat_band_sealevel(abt_sealevel >= 24)                               = 7; 

%% Final Latitudinal Band = Sea-level Lat Band
% If the local alt band differs from sea level, we consider it a non-basal band.
final_lat_band = lat_band_sealevel;
zone_shifters = (lat_band_local ~= lat_band_sealevel);
clear lat_band_sealevel;

%% Final Altitudinal Band
% 1 = nival, 2 = alpine, 3 = subalpine, 4 = montane, 5 = premontane,
% 6 = lower montane, 7 = basal
% (Here we simply store the local alt band if it differs from sea level, 
%  otherwise 7=basal.)
final_alt_band = uint8(7 * ones(size(abt)));
final_alt_band(zone_shifters) = uint8(alt_band_local(zone_shifters));

%% Manage Edge Cases and Ecotones
% If veg_class_i == 0, it indicates no match (rare); set it to 1 (avoid zeros).
% outside of things mask_polar and maskn_nodata, this catches some small amount of 
% Andean and Himalayan territory.
veg_class_i(veg_class_i == 0) = 1;



% Ecotones are assigned if precipitation, PET ratio, or biotemperature are
% outside borders of core life zone. Computed by checking if it 
% crosses half-step in log space around zone center. 
% 1 = core life zone, 2-7 for the remainder, starting with the top triangle
% of the hexagon and working around clockwise. 
% We keep 0 to refer to the entire hexagon in uses of the coding where 
% we din't differentiate b/w core and transitional zones (i.e.,
% Penman-Monteith version of HLZ. 
if (~do_calculate_ecotones)
    eco_tones = zeros(size(veg_class_i), 'uint8');
else

eco_tones = ones(size(veg_class_i), 'uint8');

prec_edges = hlz_defs.tap; 
petrat_edges = hlz_defs.per; 
abt_edges = hlz_defs.abt;

% Precipitation ecotones
eco_tones(prec < prec_edges(veg_class_i)) = 7; 
eco_tones(prec > 2.^(log2(prec_edges(veg_class_i))+1)) = 4;

% PET ratio ecotones
eco_tones(petrat < petrat_edges(veg_class_i)) = 3; 
eco_tones(petrat > 2.^(log2(petrat_edges(veg_class_i))+1)) = 6;

% Biotemperature ecotones
eco_tones(abt < abt_edges(veg_class_i)) = 2; 
eco_tones(abt > 2.^(log2(abt_edges(veg_class_i))+1)) = 5;

end

%% Polar & Out-of-Bounds Mask
% Mark anything below min_abt or in those polar hex indices as polar desert.
mask_polar = (abt <= min_abt | veg_class_i == 2 | veg_class_i == 3 | veg_class_i == 4) & ~mask_nodata;

% Out-of-bounds mask: precipitation or ratio outside modeled range 
mask_out_of_bounds = (prec < min_prec | prec >= max_prec | ...
                      petrat < min_petrat | petrat >= max_petrat) ...
                     & ~mask_polar & ~mask_nodata;

% Assign polar desert to polar areas
veg_class_i(mask_polar) = polar_desert_vegclass;
eco_tones(mask_polar) = 0;  % No transitional ecotones in polar deserts

%% Build Final HLZ Code
% Code format (4 digits):
%   [3 digits for veg_class_i | 1 digit for altitude_band | 1 digit for lat_band | 1 digit for ecotone]
% To implement, we do 1000 * veg_class_i + 100 * altitude_band + 10 * lat_band + ecotone
total_hlz_eco = ...
    1000 * uint16(veg_class_i) + ...
     100 * uint16(final_alt_band) + ...
      10 * uint16(final_lat_band) + ...
           uint16(eco_tones);

% Mark nodata and out-of-bounds
total_hlz_eco(mask_nodata)     = no_data_code;
total_hlz_eco(mask_out_of_bounds) = out_of_bounds_code;


%% Write GeoTIFF (With Ecotones)
geotiffwrite(fname, total_hlz_eco, georef);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End of script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
