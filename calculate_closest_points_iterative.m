function R = calculateClosestPointsIterative(prec, abt, petrat, F)
    % calculateClosestPointsIterative computes the closest point in F for each point in H
    % in an iterative manner to reduce memory usage.
    %
    % Input:
    % - prec: MxN matrix of doubles (precipitation values)
    % - abt: MxN matrix of doubles (biotemperature values)
    % - pet: MxN matrix of doubles (potential evapotranspiration values)
    % - F:   Gx3 matrix, where each row is a point in 3D space
    %
    % Output:
    % - R:   MxN matrix where R(m,n) is the row index of F corresponding
    %        to the closest point to (prec(m,n), abt(m,n), pet(m,n))
    %

    % --- 1) Reshape into a list of (M*N) points ---
    [M, N] = size(prec);
    H = [prec(:), abt(:), petrat(:)];  % size = (M*N, 3)
    nPoints = size(H, 1);
    G = size(F, 1);

    % --- 2) Initialize minDist2 and bestIdx ---
    minDist2 = inf(nPoints, 1);  % Track minimum distance^2 found so far
    bestIdx  = zeros(nPoints, 1, 'uint32'); 
    % (uint32 or double—whichever you prefer for storing indices)

    % --- 3) Loop over each row in F ---
    for g = 1 : G
        % Current point in F is F(g,:)
        
        % --- 4) Compute distances from H to F(g,:) in a vectorized way ---
        % dist2 is (M*N)x1
        diffMat = H - F(g, :);       % Subtract the single row from all points in H
        dist2   = sum(diffMat.^2, 2);% Compute squared distance for each point in H
        
        % Compare with current minDist2
        idx = dist2 < minDist2;     
        minDist2(idx) = dist2(idx); % Update where smaller
        bestIdx(idx)  = g;          % Store the index of F
    end
    
    % --- 5) Reshape bestIdx back into MxN ---
    R = reshape(bestIdx, [M, N]);
end
