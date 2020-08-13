function err = opt_core(x, brain_B0map, param, fov)%(coilPos, rCyln, param)
    % x: n*3 (z, theta, r)
    % brain_B0map contains NAN for voxels out of ROI (masked brain)
    shim_err = zeros(param.b0mapNTrain, 1);
    shim_std = zeros(param.b0mapNTrain, 1);
    z        = x(:,1);
    theta    = x(:,2);
    rCoil    = x(:,3);    
    coilpos  = coil_pos_make(z, theta, rCoil, param.cylnR, param.coilDiv, param.coilShape);

    fov_grids = [fov.fov_x(:), fov.fov_y(:), fov.fov_z(:)];
    b1_z    = zeros(param.coilN, size(fov_grids,1));
    parfor i=1:param.coilN % parfor
        current = conv2bs_sim_format(coilpos{i});
        b1_z(i,:) = b1sim(current, fov_grids) * 42.57e6 * param.coilTurn; % you can use the mex file for faster calculation  % b1sim_mex
    end
    b1_z = reshape(b1_z, [param.coilN, fov.fov_size]);
    if param.shimDCL % is dynamic current limitation enabled
        param.shimCUL = opt_currentAdj(param.shimCL, param.coilRUL, rCoil);
        param.shimCLL = -param.shimCUL;
    end
    
    if rank(reshape(b1_z, param.coilN, [])) ~= param.coilN
        disp('Not a full rank matrix');
%         x
    end
    % parfor is not efficient here due to huge data transfering to workers which
    % makes the overall run-time longer (even in local)  
    shimmed_brain = cell(1,param.b0mapNTrain);
    for i=1:param.b0mapNTrain
        % I got this warning when 'pinv' was used for shimming: Matrix is close to singular or badly scaled
        shimmed_brain{i} = opt_core_shim(brain_B0map{i}, b1_z, param);
        shim_err(i) = double(nansum(shimmed_brain{i}(:).^2));
        shim_std(i) = nanstd(shimmed_brain{i}(:));
    end
    
    data_outfuns = struct('shim_std', shim_std);
    assignin('base', 'data_outfuns', data_outfuns); % export to workspace to share with opt_outfun
    overlap = 0;
    if param.nonlconCoef > 0
        overlap = param.nonlconCoef * opt_circlecon(x, param);
    end
    err = sum(shim_err(:)) + overlap; % second part is nonlcon    
    %err = nanstd(shim_error);
end

