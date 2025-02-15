function T = make_unique_code_table(codes, vegdef)
% make_code_table - Save HLZ codes and their decoded names to a CSV file.
%
% Syntax:
%    make_code_table(codes, vegdef)
%
% Inputs:
%    codes      - A numeric array of HLZ codes.
%    vegdef     - Vegetation definitions used by hlz_decode (that is hlz_defs.veg_class). %

% Description:
%    For each HLZ code in the array, the function calls the standalone 
%    hlzdecode function to obtain a human-readable name
%


    % Ensure codes is a column vector for consistent table creation.
    uniq_codes = unique(unique(codes)); 
    uniq_codes = uniq_codes(:);
    n_uniqs = numel(uniq_codes);
    names = cell(n_uniqs,1);

    % Loop over each code, decoding it with hlzdecode.
    for k = 1:n_uniqs
        names{k} = hlz_decode(vegdef, uniq_codes(k));
    end

    % Create a table with two columns: Code and Name.
    T = table(uniq_codes, names, 'VariableNames', {'Code', 'Name'});
end