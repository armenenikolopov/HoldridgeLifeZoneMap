function str = hlz_decode(vegdefs, code)
%HLZDECODE Decode a Holdridge Life Zone (HLZ) code into a descriptive string.
%
%   STR = HLZDECODE(VEGDEFS, CODE) returns a string describing the
%   Holdridge Life Zone based on the given HLZ code.
%
%   The HLZ code is composed of four parts:
%
%       CODE = 1000 * VEG_CLASS_I + 100 * ALT_BAND + 10 * LAT_BAND + ECOTONE
%
%   where:
%       VEG_CLASS_I : Vegetation class index (derived from HLZ definitions)
%       ALT_BAND    : Altitudinal band index:
%                       1 = nival  
%                       2 = alpine  
%                       3 = subalpine  
%                       4 = montane  
%                       5 = premontane  
%                       6 = lower montane  
%                       7 = basal
%       LAT_BAND    : Latitudinal band index:
%                       1 = polar  
%                       2 = subpolar  
%                       3 = boreal  
%                       4 = cool temperate  
%                       5 = warm temperate  
%                       6 = subtropical  
%                       7 = tropical
%       ECOTONE     : Ecotone indicator:
%                       0 = undefined (core or transitional life zone),
%                       this is just the hexagon. 
%                       1 = core life zone 
%                     > 0 = transitional life zone / ecotone.  
%
%   Special Cases:
%       - CODE == 1: The area lies outside the HLZ parameters.
%       - CODE == 0: There is no data.
%
%   Inputs:
%       vegdefs : A string array (or cell array of strings) containing
%                 vegetation definitions, indexed by VEG_CLASS_I.
%       code    : A numeric HLZ code, the output of the hlz classifier. 
%
%   Output:
%       str     : A plain English string describing the life zone per 
%                 Holdridge 1967, with transitional zone description if
%                 pressent. 
%
%   Example:
%       description = hlzdecode(vegdefs, 19263);
%       % Might return: "subtropical alpine rain forest - hyperhumid transitional life zone"
%
%---------------------------------------------------------------------------
% Define Special Codes
%---------------------------------------------------------------------------
OUT_OF_BOUNDS_CODE = 1;  % Indicates an area outside HLZ parameters
NO_DATA_CODE       = 0;  % Indicates missing data

% Handle special cases immediately.
if code == OUT_OF_BOUNDS_CODE
    str = "No vegetation, outside of HLZ parameters";
    return;
elseif code == NO_DATA_CODE
    str = "No data";
    return;
end

%---------------------------------------------------------------------------
% Decode HLZ Code Components
%
%   The code is decomposed as follows:
%       VEG_CLASS_I = floor(code / 1000)
%       ALT_BAND    = floor(mod(code, 1000) / 100)
%       LAT_BAND    = floor(mod(code, 100) / 10)
%       ECOTONE     = mod(code, 10)
%---------------------------------------------------------------------------
veg_class_i = int32(idivide(int32(code), 1000, 'floor'));        % Vegetation class index
alt_band    = int32(idivide(mod(int32(code), 1000), 100, 'floor')); % Altitudinal band
lat_band    = int32(idivide(mod(int32(code), 100), 10, 'floor'));    % Latitudinal band
ecotone     = int32(mod(int32(code), 10));                           % Ecotone indicator

%---------------------------------------------------------------------------
% Define Descriptive Names for Each Zone Component
%---------------------------------------------------------------------------

% Latitudinal Bands (indices 1 to 7)
latBandNames = { ...
    'polar', ...
    'subpolar', ...
    'boreal', ...
    'cool temperate', ...
    'warm temperate', ...
    'subtropical', ...
    'tropical' ...
};

% Altitudinal Bands (indices 1 to 7)
% Note: A trailing space is added for formatting (except for index 7).
altBandNames = { ...
    'nival ', ...
    'alpine ', ...
    'subalpine ', ...
    'montane ', ...
    'premontane ', ...
    'lower montane ', ...
    '' ...
};

% Ecotone/Core Descriptions (indices 1 to 7)
% In this coding scheme, an ECOTONE value of 0 that it is not defined
% whether the location is core or transitional/ecotone.
% small point, we index by ecotone index +1, so 0 = '', 1 = 'core life
% zone'. 
ecotoneNames = { ...
    '', ...
    ' - core life zone', ...
    ' - hyperthermal transitional life zone', ...
    ' - hyperhumid transitional life zone', ...
    ' - hyperpluvial transitional life zone', ...
    ' - hypothermal transitional life zone', ...
    ' - hypohumid transitional life zone', ...
    ' - hypopluvial transitional life zone' ...
};

%---------------------------------------------------------------------------
% Build the Descriptive String
%---------------------------------------------------------------------------

% Combine the latitudinal band, altitudinal band, vegetation
% definition and ecotone. If ecotone == 0, it only appends ''. 
str = latBandNames{lat_band} + " " + altBandNames{alt_band} + ...
    vegdefs(veg_class_i) + ecotoneNames{ecotone +1};  %note ecotone+1


end
