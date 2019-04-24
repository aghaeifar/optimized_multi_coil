function current = conv2bs_sim_format(coilpos)

% convert to the proper format for biot-savart simulator
    coilDiv = size(coilpos.data, 2) - 1;
    current = cell(1, coilDiv); % must be a row! column is not working for mex simulator 
    for j=1:coilDiv
        current{j}.start = coilpos.data(:,j)'; % must be a row! column is not working for mex simulator 
        current{j}.stop  = coilpos.data(:,j+1)';
    end
end