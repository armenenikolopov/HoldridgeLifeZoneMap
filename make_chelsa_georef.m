%% CHELSA Grid Parameters
rows       = 20880;
cols       = 43200;
% CHELSA extents (with half-arc-second offset due to pixel-center referencing)
west       = -180.0001388888;
south_orig = -90.0001388888;  % original CHELSA south extent (includes offset)
east       =  179.9998611111;
north      =  83.9998611111;
resolution = 0.0083333333;    % cell size in degrees

%% Note on the Offset:
% CHELSA data use pixel-center referencing.
% This means the full extent as defined by the outside edges of the pixels 
% differs from integer degrees by 0.000138888888 (half-arc-second).
% When overlaying with GTOPO30 (which uses pixel edge referencing), you may see a shift.
%
% For CHELSA processing, use the provided extents as-is.

%% Step 1: Create the Default Referencing Object with Valid Limits
% MATLAB requires latitude limits to be within [-90, 90]. Since south_orig is slightly below -90,
% we must use -90 for MATLAB's internal validation.
south_adj  = -90;  % Adjusted for MATLAB validation

R_default = georefcells([south_adj, north], [west, east], [rows, cols]);
disp('Default Referencing Object (using adjusted south for MATLAB validation):');
disp(R_default);

%% Step 2: Manually Edit the Referencing Object (via a struct) to Reflect CHELSA Values
R_mod = struct(R_default);

% Override the LatitudeLimits with the original CHELSA south value
R_mod.LatitudeLimits = [south_orig, north];
R_mod.LongitudeLimits = [west, east];
R_mod.RasterSize      = [rows, cols];
R_mod.CellExtentInLatitude  = (north - south_orig) / rows;
R_mod.CellExtentInLongitude = (east - west) / cols;
% The intrinsic limits remain based on the number of rows/columns and cell centers.
% Typically, these are [0.5, rows+0.5] and [0.5, cols+0.5].

disp('Modified Referencing Object (as a struct with CHELSA values):');
disp(R_mod);
R_mod.ColumnsStartFrom = 'north';  %hack -ae
georef = R_mod;

%% Example: Writing a GeoTIFF with the WGS84 CRS
% When writing the GeoTIFF, the EPSG code 4326 (WGS84) is used.
% Assuming your raster data is stored in a variable called 'data', use:
%
% geotiffwrite('CHELSA_pr.tif', data, R_default, 'CoordRefSysCode', 4326);
%
% Note: Use R_default (which passed MATLAB validation) for geotiffwrite.
% Document that the CHELSA data have a half-arc-second offset as per CHELSA metadata.
