function newCurr = opt_currentAdj(defCurr, defR, newR)
    ratio              = defR ./ newR;
    newCurr            = ratio .* defCurr; % Amperage, shim coils current lower limit when param.shim_algo_inner is not 'pinv'  
    newCurr(newCurr>3) = 3;  % Amplifier can't supply more currents  
end