
%Location for CHELSA2.1 data for 1981-2010 for prec,pet,and tas
%(precipitation, potential evapotranspiration, and annual temperature
prec_data_dir = "/Volumes/T7 Shield/Data/CHELSA/chelsav2/GLOBAL/climatologies/1981-2010/pr";
pet_data_dir  = "/Volumes/T7 Shield/Data/CHELSA/chelsav2/GLOBAL/climatologies/1981-2010/pet";
tas_data_dir  = "/Volumes/T7 Shield/Data/CHELSA/chelsav2/GLOBAL/monthly/tas";
prec_fname_format = "CHELSA_pr_%0.2d_1981-2010_V.2.1.tif";
pet_fname_format = "CHELSA_pet_penman_%0.2d_1981-2010_V.2.1.tif";
tas_fname_format = "CHELSA_tas_%0.2d_%0.4d_V.2.1.tif";

elev_path = "/Volumes/T7 Shield/Data/GMTED2010/mean/GMTED_mosaic_clipped.tif"; 

% Dimensions of the CHELSA 2.1 rasters (30s resolution)
width  = 43200; 
height = 20880; 

make_chelsa_georef; 


% Initialize a logical mask to keep track of valid data (where all data are present)
mask = true(height, width);



annual_prec = zeros(height, width, "single");  % accumulator for annual precipitation

tic
for k = 1:12
    fprintf("Calculating precipitation for month %d\n", k);
    
    % Build the monthly PREC filename, then read data
    fname_prec = fullfile(prec_data_dir, sprintf(prec_fname_format, k));
    [data_prec, ~] = readgeoraster(fname_prec);
    info_prec = georasterinfo(fname_prec);
    data_prec = single(data_prec);

    % Update mask wherever precipitation data is missing
    mask = mask & ~(data_prec == info_prec.MissingDataIndicator);

    % Add this month's precipitation to the annual total
    annual_prec = annual_prec + single(data_prec);
end
toc

%Account for CHELSA scaling of 0.1 with 0 offset for pr (precipitation)
annual_prec = annual_prec * 0.1; 

% Write out the annual precipitation raster
geotiffwrite("/Users/armen/Documents/MATLAB/chelsa_hlz/data_calculated/prec_annual.tif", annual_prec, georef);


annual_pet = zeros(height, width, "single");  % accumulator for annual PET
%calculate PET 
tic
for k = 1:12
    fprintf("Calculating PET for month %d\n", k);
    
    % Build the monthly pet filename, then read data
    fname_pet = fullfile(pet_data_dir, sprintf(pet_fname_format, k));
    [data_pet, ~] = readgeoraster(fname_pet);
    info_pet = georasterinfo(fname_pet);
    data_pet = single(data_pet);

    % Update mask wherever pet data is missing
    mask = mask & ~(data_pet == info_pet.MissingDataIndicator); 

    % Add this month's pet to the annual total
    annual_pet = annual_pet + single(data_pet);
end
toc

%Account for CHELSA scaling of 0.01 with 0 offset for pet)
annual_pet = annual_pet * 0.01; 
% Write out the annual precipitation raster
geotiffwrite("/Users/armen/Documents/MATLAB/chelsa_hlz/data_calculated/pet_annual.tif", annual_pet, georef);

tic

% Month lengths for a non-leap year & total days
month_lengths_standard = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
totalDays = 365;  % used for weighting monthly contributions
LAPSE_RATE = 0.006;

% Preallocate accumulators and year counter
annual_biotemp_sum = zeros(height, width, 'single');
annual_sealevel_biotemp_sum = zeros(height, width, 'single');
n_years = 0;


%LOAD ELEVATION
[elev,elev_georef] = readgeoraster(elev_path);
elev = single(elev);
tic
for year = 1981:2010  % Modify range as needed (e.g., 1981:2010)
    fprintf("Calculating biotemperature for year %d\n", year);
    
    % Determine if the current year is a leap year
    if (mod(year, 4) == 0 && (mod(year, 100) ~= 0 || mod(year, 400) == 0))
        monthLengths = month_lengths_standard;
        monthLengths(2) = 29;  % February has 29 days in a leap year
        totalDays = 366;
    else
        monthLengths = month_lengths_standard;
        totalDays = 365;
    end
    
    % Initialize the accumulators for the current year's annual biotemperature
    annual_biotemp = zeros(height, width, 'single');
    annual_sealevel_biotemp = zeros(height, width, 'single');
    
    for month = 1:12  % Modify to 1:12 for all months
        fprintf("  Processing month %02d\n", month);
        
        % Construct the filename for the current month and year
        fname_tas = fullfile(tas_data_dir, sprintf(tas_fname_format, month, year));
        
        % Read the monthly temperature data and its geographic reference
        [data_tas, ~] = readgeoraster(fname_tas);
        info_tas = georasterinfo(fname_tas);
        
        % Update the mask: mark pixels with missing data as invalid
        mask = mask & ~(data_tas == info_tas.MissingDataIndicator);
        
        % Convert temperature data to single precision
        data_tas = single(data_tas) * 0.1 - 273.15; %conversion !!!! from CHELSA technical document. it's stored in shrunk Kelvin. 
        
        
        % Compute sealevel adjusted temperature using the lapse rate
        data_sealevel = data_tas + elev * LAPSE_RATE;
        
        % Apply the biotemperature definition for actual temperature:
        %   - Set negative temperatures to 0.
        %   - Cap temperatures at 30°C.
        data_biotemp = max(data_tas, 0);
        data_biotemp = min(data_biotemp, 30);
        
        % Apply the biotemperature definition for sealevel-adjusted temperature:
        data_sealevel_biotemp = max(data_sealevel, 0);
        data_sealevel_biotemp = min(data_sealevel_biotemp, 30);
        
        % Weight the month's biotemperature by its fraction of the total days in the year
        weight = monthLengths(month) / totalDays;
        annual_biotemp = annual_biotemp + data_biotemp * weight;
        annual_sealevel_biotemp = annual_sealevel_biotemp + data_sealevel_biotemp * weight;
    end
    
    % Accumulate the annual values
    annual_biotemp_sum = annual_biotemp_sum + annual_biotemp;
    annual_sealevel_biotemp_sum = annual_sealevel_biotemp_sum + annual_sealevel_biotemp;
    n_years = n_years + 1;
end
toc

% Calculate the multi-year average annual biotemperature
mean_biotemp = annual_biotemp_sum / n_years;
mean_sealevel_biotemp = annual_sealevel_biotemp_sum / n_years;

% Optionally, set pixels marked as invalid in the mask to NaN
mean_biotemp(~mask) = NaN;
mean_sealevel_biotemp(~mask) = NaN;

% Write out the averaged biotemperature rasters
output_fname = "/Users/armen/Documents/MATLAB/chelsa_hlz/data_calculated/biotemp_annual.tif";
geotiffwrite(output_fname, mean_biotemp, georef);

output_fname_sealevel = "/Users/armen/Documents/MATLAB/chelsa_hlz/data_calculated/biotemp_sealevel_annual.tif";
geotiffwrite(output_fname_sealevel, mean_sealevel_biotemp, georef);

geotiffwrite("./data_calculated/nodata_mask.tif", ~mask, georef);

fprintf("Average annual biotemperature (and sealevel-adjusted) calculation complete.\n");